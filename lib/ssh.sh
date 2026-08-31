#!/bin/bash
# SSH Server Management

start_ssh() {
    local distro="$1"
    echo -e "${BLUE}Starting SSH server...${RESET}"
    proot-distro login "$distro" -- service ssh start || proot-distro login "$distro" -- /etc/init.d/ssh start
    
    local ip
    ip=$(get_local_ip 2>/dev/null || echo "127.0.0.1")
    echo ""
    draw_card "OpenSSH Server Started" \
        "${CYAN}SSH Command:${RESET}    ${GREEN}ssh user@${ip} -p 2222${RESET}" \
        "${CYAN}Connect from:${RESET}   Terminal / PuTTY / Termius / JuiceSSH" \
        "${CYAN}Port:${RESET}           2222 (PRoot default) or 22"
}

stop_ssh() {
    local distro="$1"
    echo "Stopping SSH server..."
    proot-distro login "$distro" -- service ssh stop || proot-distro login "$distro" -- /etc/init.d/ssh stop
}

is_ssh_running() {
    local distro="$1"
    proot-distro login "$distro" -- pgrep sshd &>/dev/null
}
