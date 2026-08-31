#!/bin/bash
# Unified service management for Linux-on-Android
# Manages SSH, VNC, Desktop, and custom services with start/stop/restart/status

# Service registry
declare -A SERVICES
SERVICES["ssh"]="OpenSSH Server"
SERVICES["vnc"]="TightVNC Server"
SERVICES["desktop"]="Desktop Environment"
SERVICES["custom"]="Custom Service"

# Service status indicators
SERVICE_RUNNING="●"
SERVICE_STOPPED="○"
SERVICE_ERROR="✗"

# Get service PID
get_service_pid() {
    local service="$1"
    case "$service" in
        ssh)
            pgrep -f "sshd" | head -1
            ;;
        vnc)
            pgrep -f "Xvnc" | head -1
            ;;
        desktop)
            pgrep -f "startlxde|startxfce4" | head -1
            ;;
        *)
            echo ""
            ;;
    esac
}

# Check if service is running
is_service_running() {
    local service="$1"
    local pid=$(get_service_pid "$service")
    [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# Get service port
get_service_port() {
    local service="$1"
    case "$service" in
        ssh)
            netstat -tlnp 2>/dev/null | grep sshd | awk '{print $4}' | cut -d: -f2 | head -1
            ;;
        vnc)
            netstat -tlnp 2>/dev/null | grep Xvnc | awk '{print $4}' | cut -d: -f2 | head -1
            ;;
        *)
            echo "N/A"
            ;;
    esac
}

# Start service
start_service() {
    local service="$1"
    echo "Starting ${SERVICES[$service]}..."
    
    case "$service" in
        ssh)
            if is_service_running "ssh"; then
                echo "${YELLOW}SSH is already running${RESET}"
                return 0
            fi
            if command -v sshd >/dev/null 2>&1; then
                sshd
                sleep 1
                if is_service_running "ssh"; then
                    echo "${GREEN}✓ SSH started on port $(get_service_port ssh)${RESET}"
                    return 0
                else
                    echo "${RED}✗ Failed to start SSH${RESET}"
                    return 1
                fi
            else
                echo "${RED}✗ sshd not found${RESET}"
                return 1
            fi
            ;;
        vnc)
            if is_service_running "vnc"; then
                echo "${YELLOW}VNC is already running${RESET}"
                return 0
            fi
            if command -v vncserver >/dev/null 2>&1; then
                vncserver :1 -geometry 1920x1080 -depth 24
                sleep 2
                if is_service_running "vnc"; then
                    echo "${GREEN}✓ VNC started on display :1${RESET}"
                    return 0
                else
                    echo "${RED}✗ Failed to start VNC${RESET}"
                    return 1
                fi
            else
                echo "${RED}✗ vncserver not found${RESET}"
                return 1
            fi
            ;;
        desktop)
            if is_service_running "desktop"; then
                echo "${YELLOW}Desktop is already running${RESET}"
                return 0
            fi
            if command -v startlxde >/dev/null 2>&1; then
                startlxde &
                sleep 2
                if is_service_running "desktop"; then
                    echo "${GREEN}✓ Desktop environment started${RESET}"
                    return 0
                else
                    echo "${RED}✗ Failed to start desktop${RESET}"
                    return 1
                fi
            else
                echo "${RED}✗ Desktop environment not found${RESET}"
                return 1
            fi
            ;;
        *)
            echo "${RED}Unknown service: $service${RESET}"
            return 1
            ;;
    esac
}

# Stop service
stop_service() {
    local service="$1"
    echo "Stopping ${SERVICES[$service]}..."
    
    local pid=$(get_service_pid "$service")
    if [[ -z "$pid" ]]; then
        echo "${YELLOW}${SERVICES[$service]} is not running${RESET}"
        return 0
    fi
    
    case "$service" in
        ssh)
            pkill -f sshd
            sleep 1
            ;;
        vnc)
            vncserver -kill :1 2>/dev/null || pkill -f Xvnc
            sleep 1
            ;;
        desktop)
            pkill -f "startlxde|startxfce4"
            sleep 1
            ;;
        *)
            kill "$pid" 2>/dev/null
            ;;
    esac
    
    if ! is_service_running "$service"; then
        echo "${GREEN}✓ ${SERVICES[$service]} stopped${RESET}"
        return 0
    else
        echo "${RED}✗ Failed to stop ${SERVICES[$service]}${RESET}"
        return 1
    fi
}

# Restart service
restart_service() {
    local service="$1"
    stop_service "$service"
    sleep 1
    start_service "$service"
}

# Show service status
show_service_status() {
    local service="$1"
    local name="${SERVICES[$service]}"
    local status
    
    if is_service_running "$service"; then
        status="${GREEN}${SERVICE_RUNNING} Running${RESET}"
    else
        status="${RED}${SERVICE_STOPPED} Stopped${RESET}"
    fi
    
    local port=$(get_service_port "$service")
    
    printf "%-15s %s" "$name:" "$status"
    [[ "$port" != "N/A" && -n "$port" ]] && printf " (Port: %s)" "$port"
    printf "\n"
}

# Show all services status
show_all_services_status() {
    local status_lines=()
    for service in "${!SERVICES[@]}"; do
        status_lines+=("$(show_service_status "$service")")
    done
    draw_card "Service Status" "${status_lines[@]}"
}

# Clean stale lock files
clean_stale_locks() {
    echo "Cleaning stale lock files..."
    local locks_cleaned=0
    
    # SSH lock files
    if [[ -d /var/run ]]; then
        find /var/run -name "sshd.pid" -type f -delete 2>/dev/null && ((locks_cleaned++))
    fi
    
    # VNC lock files
    if [[ -d /tmp ]]; then
        find /tmp -name ".X*-lock" -type f -delete 2>/dev/null && ((locks_cleaned++))
        find /tmp -name ".X11-unix" -type d -exec rm -rf {} + 2>/dev/null && ((locks_cleaned++))
    fi
    
    echo "${GREEN}✓ Cleaned $locks_cleaned stale lock(s)${RESET}"
}

# Service management menu
service_menu() {
    while true; do
        draw_header "Service Management"
        show_all_services_status
        echo ""
        draw_card "Quick Actions" \
            "${YELLOW} 1)${RESET} Start Service" \
            "${YELLOW} 2)${RESET} Stop Service" \
            "${YELLOW} 3)${RESET} Restart Service" \
            "${YELLOW} 4)${RESET} Clean Stale Locks" \
            "${YELLOW} 5)${RESET} View Remote Connection URLs (SSH & VNC)" \
            "${YELLOW} 6)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        menu_prompt
        read -r choice
        
        case "$choice" in
            1)
                echo -ne "${CYAN}Enter service (ssh/vnc/desktop) [or 'b' to back]:${RESET} "
                read -r svc
                if [[ -n "$svc" && ! "$svc" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
                    start_service "$svc"
                    echo ""
                    read -rp "Press Enter to continue..." _
                fi
                ;;
            2)
                echo -ne "${CYAN}Enter service (ssh/vnc/desktop) [or 'b' to back]:${RESET} "
                read -r svc
                if [[ -n "$svc" && ! "$svc" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
                    stop_service "$svc"
                    echo ""
                    read -rp "Press Enter to continue..." _
                fi
                ;;
            3)
                echo -ne "${CYAN}Enter service (ssh/vnc/desktop) [or 'b' to back]:${RESET} "
                read -r svc
                if [[ -n "$svc" && ! "$svc" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
                    restart_service "$svc"
                    echo ""
                    read -rp "Press Enter to continue..." _
                fi
                ;;
            4)
                clean_stale_locks
                echo ""
                read -rp "Press Enter to continue..." _
                ;;
            5)
                show_remote_access_card
                echo ""
                read -rp "Press Enter to continue..." _
                ;;
            6|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT])
                break
                ;;
            *)
                echo -e "${RED}Invalid option${RESET}"
                sleep 1
                ;;
        esac
    done
}
