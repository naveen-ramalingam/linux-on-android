#!/bin/bash
# Distribution management using proot-distro

source "$LIB_PATH/colors.sh"

ensure_proot_distro() {
    if ! command -v proot-distro &>/dev/null; then
        echo -e "${BLUE}proot-distro is not installed. Installing it now...${RESET}"
        if command -v pkg &>/dev/null; then
            pkg update -y && pkg install -y proot-distro
        elif command -v apt &>/dev/null; then
            apt update -y && apt install -y proot-distro
        fi
        
        if ! command -v proot-distro &>/dev/null; then
            echo -e "${RED}Failed to install proot-distro. Please run 'pkg install proot-distro' manually.${RESET}"
            return 1
        fi
        echo -e "${GREEN}✓ proot-distro installed successfully.${RESET}"
    fi
    return 0
}

list_distros() {
    ensure_proot_distro || return 1
    proot-distro list 2>/dev/null || echo "Error: proot-distro not available"
}

is_distro_installed() {
    [[ -n "$1" ]] && proot-distro list 2>/dev/null | grep -E "^[[:space:]]*$1:?[[:space:]]+.*installed" >/dev/null 2>&1
}

get_installed_distro() {
    proot-distro list 2>/dev/null | grep -E "installed" | grep -v "not installed" | awk -F'[: ]+' '{print $1}' | head -n 1
}

install_distro() {
    local distro="${1:-ubuntu}"
    ensure_proot_distro || return 1
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