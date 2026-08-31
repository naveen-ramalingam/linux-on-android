#!/bin/bash
# VNC and Desktop Management

source "$LIB_PATH/colors.sh"

start_vnc() {
    local distro="$1"
    echo -e "${BLUE}Starting VNC server...${RESET}"
    proot-distro login "$distro" -- bash -c 'export DISPLAY=:1 && vncserver :1 -geometry 1280x720 -depth 24 2>&1'
}

stop_vnc() {
    local distro="$1"
    echo -e "${RED}Stopping VNC server...${RESET}"
    proot-distro login "$distro" -- vncserver -kill :1 2>/dev/null
}

restart_vnc() {
    local distro="$1"
    stop_vnc "$distro"
    sleep 1
    start_vnc "$distro"
}

is_vnc_running() {
    local distro="$1"
    proot-distro login "$distro" -- pgrep Xvnc &>/dev/null
}

get_vnc_display() {
    local distro="$1"
    proot-distro login "$distro" -- cat ~/.vnc/*.log 2>/dev/null | grep "desktop is" | tail -n 1 || echo "Unknown"
}