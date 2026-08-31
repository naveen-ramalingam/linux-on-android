#!/bin/bash
# Network detection, IP discovery, and Remote Access integration for SSH/VNC

source "$LIB_PATH/colors.sh"
source "$LIB_PATH/ui.sh"

get_local_ip() {
    local ip=""
    # Method 1: ip -4 addr
    ip=$(ip -4 addr show 2>/dev/null | grep -E 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d/ -f1 | head -n 1)
    # Method 2: hostname -I
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    # Method 3: ifconfig
    if [[ -z "$ip" ]]; then
        ip=$(ifconfig 2>/dev/null | grep -E 'inet (addr:)?' | grep -v '127.0.0.1' | awk '{print $2}' | sed 's/addr://' | head -n 1)
    fi
    echo "${ip:-127.0.0.1}"
}

get_active_interfaces() {
    ip link show 2>/dev/null | awk -F: '$0 !~ "lo|vir|wl" {print $2}' | tr -d ' ' || echo "wlan0"
}

get_all_ips() {
    local list
    list=$(ip -4 addr show 2>/dev/null | awk '/inet / && !/127.0.0.1/ {split($2, a, "/"); print $NF ": " a[1]}')
    if [[ -z "$list" ]]; then
        local lip
        lip=$(get_local_ip)
        echo "wlan0: $lip"
    else
        echo "$list"
    fi
}

show_remote_access_card() {
    local distro="${1:-$(get_installed_distro)}"
    local local_ip
    local_ip=$(get_local_ip)
    
    local username="user"
    local vnc_pw="1234"
    local config_file="$CONFIG_DIR/$distro.conf"
    if [[ -f "$config_file" ]]; then
        # shellcheck source=/dev/null
        source "$config_file"
    fi
    username="${USERNAME:-user}"
    vnc_pw="${VNC_PASSWD:-1234}"

    local ssh_port="2222"
    if is_service_running "ssh" 2>/dev/null; then
        local detected_port
        detected_port=$(get_service_port "ssh" 2>/dev/null)
        [[ "$detected_port" =~ ^[0-9]+$ ]] && ssh_port="$detected_port"
    fi

    draw_card "Remote Connection Hub (IP: $local_ip)" \
        "${BOLD}📱 OpenSSH Remote Terminal:${RESET}" \
        "  Command: ${GREEN}ssh ${username}@${local_ip} -p ${ssh_port}${RESET}" \
        "  Mobile Apps: JuiceSSH / Termius (Host: ${local_ip}, Port: ${ssh_port})" \
        "" \
        "${BOLD}🖥️ VNC Remote Desktop:${RESET}" \
        "  VNC Viewer Address: ${GREEN}${local_ip}:5901${RESET} (or ${GREEN}${local_ip}:1${RESET})" \
        "  VNC Password:       ${YELLOW}${vnc_pw}${RESET}" \
        "  Mobile Apps:        bVNC, RealVNC, AVNC"
}

show_network_info() {
    draw_header "Network & IP Information"
    local local_ip
    local_ip=$(get_local_ip)
    
    local all_ips
    all_ips=$(get_all_ips)
    
    local pub_ip="N/A"
    if command -v curl &>/dev/null; then
        pub_ip=$(curl -s --connect-timeout 2 ifconfig.me 2>/dev/null || echo "Offline/Blocked")
    fi
    
    draw_card "Device IP Addresses" \
        "${CYAN}Primary IP:${RESET}      ${GREEN}$local_ip${RESET}" \
        "${CYAN}Interfaces:${RESET}      $(echo "$all_ips" | tr '\n' ' ')" \
        "${CYAN}Public WAN IP:${RESET}   $pub_ip"
    echo ""
    
    show_remote_access_card "$(get_installed_distro)"
}

connect_to_remote_ssh() {
    draw_header "Connect to Remote SSH Server"
    draw_card "SSH Client Connect" \
        "Quickly connect to another remote server, PC, or VPS" \
        "directly from your Android terminal."
    echo ""
    
    echo -ne "${CYAN}Enter Remote Host IP / Domain [or 'b' to cancel]:${RESET} "
    read -r remote_ip
    if [[ -z "$remote_ip" || "$remote_ip" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
        return 0
    fi
    
    echo -ne "${CYAN}Enter SSH Port [default: 22]:${RESET} "
    read -r remote_port
    remote_port="${remote_port:-22}"
    [[ "$remote_port" =~ ^(0|[bB]|[qQ]|back|exit)$ ]] && return 0
    
    echo -ne "${CYAN}Enter Remote Username [default: root]:${RESET} "
    read -r remote_user
    remote_user="${remote_user:-root}"
    [[ "$remote_user" =~ ^(0|[bB]|[qQ]|back|exit)$ ]] && return 0
    
    echo -e "\n${BLUE}Connecting to ${remote_user}@${remote_ip}:${remote_port}...${RESET}\n"
    ssh -p "$remote_port" "${remote_user}@${remote_ip}"
    echo -e "\n${GREEN}✓ SSH session closed.${RESET}"
}

network_menu() {
    while true; do
        draw_header "Network & Remote Hub"
        local local_ip
        local_ip=$(get_local_ip)
        
        draw_card "Connection Center (Local IP: $local_ip)" \
            "${YELLOW} 1)${RESET} View Device IP & Remote Access Details" \
            "${YELLOW} 2)${RESET} Connect to a Remote SSH Server (Client)" \
            "${YELLOW} 3)${RESET} Test Network & Ping Connectivity" \
            "${YELLOW} 4)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        menu_prompt
        read -r choice
        
        case "$choice" in
            1)
                show_network_info
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            2)
                connect_to_remote_ssh
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            3)
                draw_header "Network Connectivity Test"
                echo -e "${BLUE}Testing connection to Cloudflare DNS (1.1.1.1)...${RESET}"
                if ping -c 3 1.1.1.1 2>/dev/null; then
                    echo -e "\n${GREEN}✓ Internet connectivity is active!${RESET}"
                else
                    echo -e "\n${RED}✗ Ping failed. Check Wi-Fi or mobile data.${RESET}"
                fi
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            4|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT])
                break
                ;;
            *)
                echo -e "${RED}Invalid choice.${RESET}"
                sleep 1
                ;;
        esac
    done
}
