#!/bin/bash
# Package management helpers for Linux Server Manager

# Common package stacks for quick installation
declare -A STACKS

STACKS[LAMP]="apache2 mariadb-server php php-mysql"
STACKS[LEMP]="nginx mariadb-server php-fpm php-mysql"
STACKS[DEV]="build-essential git curl wget vim tmux python3 python3-pip nodejs npm"
STACKS[MEDIA]="ffmpeg imagemagick vlc-bin"
STACKS[DATA]="postgresql postgresql-contrib redis-server sqlite3"

list_available_stacks() {
    draw_header "Software Stacks"
    for stack in "${!STACKS[@]}"; do
        draw_card "$stack Stack" \
            "${CYAN}Packages:${RESET} ${STACKS[$stack]}"
        echo ""
    done
}

install_stack() {
    local distro="$1"
    local stack_name="$2"
    
    if [[ -z "${STACKS[$stack_name]}" ]]; then
        echo -e "${RED}Unknown stack: $stack_name${RESET}"
        return 1
    fi
    
    local packages="${STACKS[$stack_name]}"
    echo -e "${BLUE}Installing $stack_name stack on $distro...${RESET}"
    echo -e "${CYAN}Packages:${RESET} $packages"
    
    proot-distro login "$distro" -- bash -lc "
        apt update
        apt install -y $packages
    "
    
    echo -e "${GREEN}Stack $stack_name installed successfully!${RESET}"
}

install_custom_packages() {
    local distro="$1"
    shift
    local packages="$*"
    
    if [[ -z "$packages" ]]; then
        echo -e "${RED}No packages specified.${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}Installing packages on $distro: $packages${RESET}"
    proot-distro login "$distro" -- bash -lc "
        apt update
        apt install -y $packages
    "
}

update_distro_packages() {
    local distro="$1"
    echo -e "${BLUE}Updating packages in $distro...${RESET}"
    proot-distro login "$distro" -- bash -lc "
        apt update && apt upgrade -y
    "
    echo -e "${GREEN}Packages updated.${RESET}"
}

cleanup_distro_packages() {
    local distro="$1"
    echo -e "${BLUE}Cleaning up unused packages in $distro...${RESET}"
    proot-distro login "$distro" -- bash -lc "
        apt autoremove -y && apt clean
    "
    echo -e "${GREEN}Cleanup complete.${RESET}"
}

package_menu() {
    local distro="$1"
    while true; do
        draw_header "Package Management ($distro)"
        draw_card "Software Options" \
            "${YELLOW} 1)${RESET} View Available Stacks" \
            "${YELLOW} 2)${RESET} Install LAMP Stack (Apache/MariaDB/PHP)" \
            "${YELLOW} 3)${RESET} Install LEMP Stack (Nginx/MariaDB/PHP)" \
            "${YELLOW} 4)${RESET} Install DEV Stack (Build tools/Git/Node/Python)" \
            "${YELLOW} 5)${RESET} Install Custom Packages" \
            "${YELLOW} 6)${RESET} Update & Upgrade Packages" \
            "${YELLOW} 7)${RESET} Cleanup Unused Packages" \
            "${YELLOW} 8)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        menu_prompt
        read -r choice

        case "$choice" in
            1) list_available_stacks; echo ""; read -rp "Press Enter to continue..." _ ;;
            2) install_stack "$distro" "LAMP"; echo ""; read -rp "Press Enter to continue..." _ ;;
            3) install_stack "$distro" "LEMP"; echo ""; read -rp "Press Enter to continue..." _ ;;
            4) install_stack "$distro" "DEV"; echo ""; read -rp "Press Enter to continue..." _ ;;
            5)
                echo -ne "${CYAN}Enter packages separated by space [or 'b' to back]:${RESET} "
                read -r pkgs
                if [[ -n "$pkgs" && ! "$pkgs" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
                    install_custom_packages "$distro" $pkgs
                    echo ""
                    read -rp "Press Enter to continue..." _
                fi
                ;;
            6) update_distro_packages "$distro"; echo ""; read -rp "Press Enter to continue..." _ ;;
            7) cleanup_distro_packages "$distro"; echo ""; read -rp "Press Enter to continue..." _ ;;
            8|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT]) break ;;
            *) echo -e "${RED}Invalid choice.${RESET}"; sleep 1 ;;
        esac
    done
}

