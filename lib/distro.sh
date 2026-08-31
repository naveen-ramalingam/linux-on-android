#!/bin/bash
# Distribution management using proot-distro

source "$LIB_PATH/colors.sh"

list_distros() {
    proot-distro list 2>/dev/null || echo "Error: proot-distro not available"
}

is_distro_installed() {
    [[ -n "$1" ]] && proot-distro list 2>/dev/null | grep -q "^$1 "
}

get_installed_distro() {
    proot-distro list 2>/dev/null | grep "installed" | awk '{print $2}' | tr -d ':' | head -n 1
}

install_distro() {
    local distro="${1:-ubuntu}"
    if is_distro_installed "$distro"; then
        echo -e "${YELLOW}Distribution '$distro' is already installed${RESET}"
        return 1
    fi
    echo -e "${BLUE}Installing $distro...${RESET}"
    proot-distro install "$distro" 2>&1
}

remove_distro() {
    local distro="${1:-}"
    if [[ -z "$distro" ]]; then
        distro=$(get_installed_distro)
        [[ -z "$distro" ]] && echo "No distribution installed" && return 1
    fi
    echo -e "${RED}Removing $distro...${RESET}"
    proot-distro remove "$distro" 2>&1
}

login_distro() {
    local distro="${1:-}"
    if [[ -z "$distro" ]]; then
        distro=$(get_installed_distro)
        [[ -z "$distro" ]] && echo "No distribution installed" && return 1
    fi
    proot-distro login "$distro" 2>&1
}