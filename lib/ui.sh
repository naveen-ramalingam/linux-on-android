#!/bin/bash
# UI Framework for mobile/portrait Termux

source "$LIB_PATH/colors.sh"

draw_header() {
    local title="$1"
    local width=40
    clear
    echo -e "${BLUE}========================================${RESET}"
    printf "${BOLD}%*s${RESET}\n" $(((${#title} + width) / 2)) "$title"
    echo -e "${BLUE}========================================${RESET}"
}

draw_status_bar() {
    local distro="$1"
    echo -e "${CYAN}----------------------------------------${RESET}"
    if [[ -n "$distro" ]]; then
        echo -e " Distro: ${GREEN}$distro${RESET}"
    else
        echo -e " Distro: ${RED}None installed${RESET}"
    fi
    echo -e " Storage: $(get_storage_free)"
    echo -e "${CYAN}----------------------------------------${RESET}"
}

menu_prompt() {
    echo -ne "${YELLOW}Select an option: ${RESET}"
}
