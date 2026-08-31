#!/bin/bash
# UI Framework for mobile/portrait Termux and TUI rendering

source "$LIB_PATH/colors.sh"

# Terminal dimensions
get_term_width() {
    local cols
    cols=$(tput cols 2>/dev/null || echo 40)
    [[ $cols -lt 40 ]] && cols=40
    [[ $cols -gt 80 ]] && cols=80
    echo "$cols"
}

# Unicode / ASCII border styles
BOX_TL="┌"
BOX_TR="┐"
BOX_BL="└"
BOX_BR="┘"
BOX_H="─"
BOX_V="│"

draw_header() {
    local title="$1"
    local width
    width=$(get_term_width)
    clear
    echo -e "${BLUE}${BOLD}╔$(printf '═%.0s' $(seq 1 $((width - 2))))╗${RESET}"
    printf "${BLUE}${BOLD}║%*s%*s║${RESET}\n" $(( (width - 2 + ${#title}) / 2 )) "$title" $(( (width - 2 - ${#title}) / 2 + (width - 2 - ${#title}) % 2 )) ""
    echo -e "${BLUE}${BOLD}╚$(printf '═%.0s' $(seq 1 $((width - 2))))╝${RESET}"
}

draw_card() {
    local title="$1"
    shift
    local lines=("$@")
    local width
    width=$(get_term_width)
    local inner_width=$((width - 4))

    echo -e "${CYAN}${BOX_TL}${BOX_H} ${BOLD}${title}${RESET}${CYAN} $(printf "${BOX_H}%.0s" $(seq 1 $((inner_width - ${#title} - 1))))${BOX_TR}${RESET}"
    for line in "${lines[@]}"; do
        printf "${CYAN}${BOX_V}${RESET} %-${inner_width}b ${CYAN}${BOX_V}${RESET}\n" "$line"
    done
    echo -e "${CYAN}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $((width - 2))))${BOX_BR}${RESET}"
}

draw_status_bar() {
    local distro="$1"
    local width
    width=$(get_term_width)
    local inner_width=$((width - 4))
    
    local rtype
    rtype=$(get_root_type 2>/dev/null || echo "No")
    
    local lip
    lip=$(get_local_ip 2>/dev/null || echo "127.0.0.1")
    
    echo -e "${CYAN}${BOX_TL}$(printf "${BOX_H}%.0s" $(seq 1 $((width - 2))))${BOX_TR}${RESET}"
    if [[ -n "$distro" ]]; then
        printf "${CYAN}${BOX_V}${RESET} Distro: ${GREEN}%-8s${RESET} IP: ${CYAN}%-15s${RESET} Root: ${YELLOW}%-7s${RESET} ${CYAN}${BOX_V}${RESET}\n" "$distro" "$lip" "$rtype"
    else
        printf "${CYAN}${BOX_V}${RESET} Distro: ${RED}%-8s${RESET} IP: ${CYAN}%-15s${RESET} Root: ${YELLOW}%-7s${RESET} ${CYAN}${BOX_V}${RESET}\n" "None" "$lip" "$rtype"
    fi
    echo -e "${CYAN}${BOX_BL}$(printf "${BOX_H}%.0s" $(seq 1 $((width - 2))))${BOX_BR}${RESET}"
}

draw_progress_bar() {
    local current="$1"
    local total="$2"
    local width=20
    local percent=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\rProgress: [${GREEN}%s${RESET}%s] %d%%" "$(printf '█%.0s' $(seq 1 $filled))" "$(printf '░%.0s' $(seq 1 $empty))" "$percent"
}

show_spinner() {
    local pid="$1"
    local msg="$2"
    local spin=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    local i=0
    while kill -0 "$pid" 2>/dev/null; do
        printf "\r${CYAN}%s${RESET} %s..." "${spin[$i]}" "$msg"
        i=$(((i + 1) % 10))
        sleep 0.1
    done
    printf "\r${GREEN}✓${RESET} %s... Done!   \n" "$msg"
}

menu_prompt() {
    echo -ne "\n${YELLOW}${BOLD}Select an option:${RESET} "
}

