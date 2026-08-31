#!/bin/bash
# Native Rooted Docker Engine Module for Linux Server Manager
# Manages dockerd, cgroups, kernel audit, and containers for rooted Android devices

source "$LIB_PATH/colors.sh"
source "$LIB_PATH/ui.sh"
source "$LIB_PATH/root.sh"
source "$LIB_PATH/network.sh"

DOCKER_LOG="${PREFIX:-/data/data/com.termux/files/usr}/var/log/dockerd.log"
DOCKER_PID_FILE="/var/run/docker.pid"

is_dockerd_running() {
    if pgrep -f "dockerd" &>/dev/null; then
        return 0
    fi
    if command -v docker &>/dev/null && docker info &>/dev/null; then
        return 0
    fi
    return 1
}

check_docker_kernel() {
    draw_header "Docker Kernel Compatibility Audit"
    
    if ! is_root_available; then
        draw_card "Root Required" \
            "${RED}Native Docker engine requires root access.${RESET}" \
            "Your device does not have active root (Magisk/KernelSU/APatch)."
        return 1
    fi
    
    echo -e "${CYAN}Analyzing Android kernel features for Docker...${RESET}\n"
    
    # 1. Namespaces
    local ns_status="${GREEN}✓ Available${RESET}"
    if [[ -d "/proc/1/ns" ]]; then
        ns_status="${GREEN}✓ Namespaces Supported (/proc/1/ns)${RESET}"
    else
        ns_status="${YELLOW}⚠ Partial/Missing Namespaces${RESET}"
    fi

    # 2. Cgroups
    local cgroup_count=0
    local cgroup_details=""
    if [[ -f "/proc/cgroups" ]]; then
        cgroup_count=$(awk '!/^#/ { if ($4 == 1) count++ } END { print count+0 }' /proc/cgroups)
        cgroup_details=$(awk '!/^#/ { if ($4 == 1) printf "%s ", $1 }' /proc/cgroups)
    fi

    # 3. Storage Driver
    local overlay_status="${RED}✗ OverlayFS Missing (will fallback to vfs)${RESET}"
    if grep -q "overlay" /proc/filesystems 2>/dev/null; then
        overlay_status="${GREEN}✓ OverlayFS Supported (overlay2)${RESET}"
    fi

    # 4. Bridge & Networking
    local bridge_status="${RED}✗ Bridge Missing${RESET}"
    if [[ -d "/sys/class/net" ]] || command -v ip &>/dev/null; then
        bridge_status="${GREEN}✓ Network Subsystems Ready${RESET}"
    fi

    draw_card "Kernel Compatibility Results" \
        "${CYAN}Kernel Version:${RESET}    $(uname -r)" \
        "${CYAN}Namespaces:${RESET}        $ns_status" \
        "${CYAN}Active Cgroups:${RESET}    ${GREEN}$cgroup_count subsystems${RESET} ($cgroup_details)" \
        "${CYAN}Storage Driver:${RESET}    $overlay_status" \
        "${CYAN}Networking:${RESET}        $bridge_status"
    
    echo ""
    if [[ $cgroup_count -ge 3 ]]; then
        draw_card "Verdict" "${GREEN}✓ Your kernel is capable of running Native Docker Engine!${RESET}"
    else
        draw_card "Verdict" "${YELLOW}⚠ Limited cgroups detected. Docker may run in unconfined/vfs mode.${RESET}"
    fi
}

setup_docker_cgroups() {
    echo -e "${BLUE}Mounting cgroup hierarchies for Docker...${RESET}"
    run_as_root "
        mkdir -p /sys/fs/cgroup /var/run /var/lib/docker /data/docker /etc/docker
        mount -t tmpfs -o uid=0,gid=0,mode=0755 cgroup /sys/fs/cgroup 2>/dev/null || true
        
        if [[ -f /proc/cgroups ]]; then
            for sys in \$(awk '!/^#/ { if (\$4 == 1) print \$1 }' /proc/cgroups); do
                mkdir -p \"/sys/fs/cgroup/\$sys\"
                mount -t cgroup -o \"\$sys\" cgroup \"/sys/fs/cgroup/\$sys\" 2>/dev/null || true
            done
        fi
    "
}

configure_docker_daemon() {
    echo -e "${BLUE}Configuring Docker daemon settings...${RESET}"
    
    local storage_driver="overlay2"
    if ! grep -q "overlay" /proc/filesystems 2>/dev/null; then
        storage_driver="vfs"
    fi
    
    run_as_root "
        mkdir -p /etc/docker /data/docker
        cat > /etc/docker/daemon.json << 'EOF'
{
  \"storage-driver\": \"$storage_driver\",
  \"iptables\": false,
  \"dns\": [\"8.8.8.8\", \"1.1.1.1\"],
  \"log-driver\": \"json-file\",
  \"log-opts\": {
    \"max-size\": \"10m\",
    \"max-file\": \"3\"
  }
}
EOF
    "
}

install_rooted_docker() {
    draw_header "Install Docker Engine"
    
    if ! is_root_available; then
        echo -e "${RED}Error: Root access is required to install and run native Docker.${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}Installing Docker packages...${RESET}"
    if [[ "$IS_TERMUX" -eq 1 ]] && command -v pkg &>/dev/null; then
        run_as_root "pkg install -y root-repo && pkg install -y docker docker-compose"
    elif command -v apt &>/dev/null; then
        run_as_root "apt update && apt install -y docker.io docker-compose || apt install -y docker"
    elif command -v apk &>/dev/null; then
        run_as_root "apk update && apk add docker docker-compose"
    else
        echo -e "${RED}Unsupported package manager. Please install 'docker' manually.${RESET}"
        return 1
    fi
    
    echo -e "\n${GREEN}✓ Docker installation complete!${RESET}"
}

start_dockerd() {
    draw_header "Start Docker Engine"
    
    if ! is_root_available; then
        echo -e "${RED}Error: Root access is required to run dockerd.${RESET}"
        return 1
    fi
    
    if is_dockerd_running; then
        echo -e "${YELLOW}Docker daemon is already running.${RESET}"
        return 0
    fi
    
    setup_docker_cgroups
    configure_docker_daemon
    
    mkdir -p "$(dirname "$DOCKER_LOG")"
    echo -e "${BLUE}Starting dockerd daemon in background...${RESET}"
    
    run_as_root "
        iptables -t nat -N DOCKER 2>/dev/null || true
        dockerd > '$DOCKER_LOG' 2>&1 &
        echo \$! > '$DOCKER_PID_FILE'
    "
    
    echo -e "${CYAN}Waiting for Docker socket to initialize...${RESET}"
    local attempts=0
    while [[ $attempts -lt 8 ]]; do
        if is_dockerd_running; then
            echo -e "${GREEN}✓ Docker daemon started successfully!${RESET}"
            return 0
        fi
        sleep 1
        ((attempts++))
    done
    
    if is_dockerd_running; then
        echo -e "${GREEN}✓ Docker daemon is active!${RESET}"
    else
        echo -e "${YELLOW}Docker process spawned. Check logs with Option 9 (View Logs).${RESET}"
    fi
}

stop_dockerd() {
    draw_header "Stop Docker Engine"
    
    if ! is_dockerd_running; then
        echo -e "${YELLOW}Docker daemon is not running.${RESET}"
        return 0
    fi
    
    echo -e "${RED}Stopping dockerd and active containers...${RESET}"
    run_as_root "
        pkill -TERM dockerd 2>/dev/null || true
        pkill -f containerd 2>/dev/null || true
        rm -f '$DOCKER_PID_FILE' /var/run/docker.sock
    "
    sleep 1
    echo -e "${GREEN}✓ Docker daemon stopped.${RESET}"
}

docker_status_dashboard() {
    draw_header "Docker Engine Status"
    
    local status="${RED}○ Stopped${RESET}"
    local version="N/A"
    local containers="N/A"
    local images="N/A"
    
    if is_dockerd_running; then
        status="${GREEN}● Running${RESET}"
        version=$(docker --version 2>/dev/null | awk '{print $3}' | tr -d ',' || echo "Unknown")
        containers=$(docker ps -q 2>/dev/null | wc -l | tr -d ' ' || echo "0")
        images=$(docker images -q 2>/dev/null | wc -l | tr -d ' ' || echo "0")
    fi
    
    draw_card "Docker Engine Overview" \
        "${CYAN}Daemon Status:${RESET}      $status" \
        "${CYAN}Docker Version:${RESET}     $version" \
        "${CYAN}Running Containers:${RESET} $containers" \
        "${CYAN}Total Images:${RESET}       $images" \
        "${CYAN}Log File:${RESET}           $DOCKER_LOG"
    
    echo ""
    if is_dockerd_running; then
        echo -e "${BOLD}Active Containers:${RESET}"
        docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null || echo "No active containers"
    fi
}

run_test_container() {
    draw_header "Run Test Container"
    
    if ! is_dockerd_running; then
        echo -e "${RED}Docker daemon is not running. Start dockerd first (Option 3).${RESET}"
        return 1
    fi
    
    draw_card "Choose Test Container" \
        "${YELLOW} 1)${RESET} Hello World (Minimal image to verify engine)" \
        "${YELLOW} 2)${RESET} Nginx Web Server (Lightweight web server on port 8080)" \
        "${YELLOW} 3)${RESET} Alpine Linux Shell (Interactive minimal container)" \
        "${YELLOW} 4)${RESET} Cancel / Back"
    echo ""
    
    echo -ne "${CYAN}Select option [1-4, or 'b']:${RESET} "
    read -r tchoice
    
    local local_ip
    local_ip=$(get_local_ip)
    
    case "$tchoice" in
        1)
            echo -e "${BLUE}Running hello-world container...${RESET}\n"
            docker run --rm hello-world
            ;;
        2)
            echo -e "${BLUE}Deploying Nginx on port 8080...${RESET}\n"
            docker run -d --name test-nginx -p 8080:80 nginx:alpine
            echo -e "\n${GREEN}✓ Nginx running!${RESET}"
            echo -e "${CYAN}Access web page at:${RESET} ${GREEN}http://${local_ip}:8080${RESET}"
            ;;
        3)
            echo -e "${BLUE}Launching Alpine container shell...${RESET}\n"
            docker run -it --rm alpine /bin/sh
            ;;
        *)
            echo -e "${YELLOW}Cancelled.${RESET}"
            ;;
    esac
}

docker_menu() {
    while true; do
        draw_header "Native Rooted Docker Hub"
        
        local dstatus="${RED}Stopped${RESET}"
        is_dockerd_running && dstatus="${GREEN}Running${RESET}"
        
        draw_card "Docker Engine ($dstatus)" \
            "${YELLOW} 1)${RESET} Docker Status & Running Containers" \
            "${YELLOW} 2)${RESET} Kernel Docker Compatibility Audit" \
            "${YELLOW} 3)${RESET} Start Docker Daemon (dockerd)" \
            "${YELLOW} 4)${RESET} Stop Docker Daemon" \
            "${YELLOW} 5)${RESET} Restart Docker Daemon" \
            "${YELLOW} 6)${RESET} Run Test Container (Nginx / Hello-World)" \
            "${YELLOW} 7)${RESET} Install / Update Docker Packages" \
            "${YELLOW} 8)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        menu_prompt
        read -r choice
        
        case "$choice" in
            1)
                docker_status_dashboard
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            2)
                check_docker_kernel
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            3)
                start_dockerd
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            4)
                stop_dockerd
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            5)
                stop_dockerd
                sleep 1
                start_dockerd
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            6)
                run_test_container
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            7)
                install_rooted_docker
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            8|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT])
                break
                ;;
            *)
                echo -e "${RED}Invalid choice.${RESET}"
                sleep 1
                ;;
        esac
    done
}
