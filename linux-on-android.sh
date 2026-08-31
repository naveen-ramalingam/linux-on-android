#!/usr/bin/env bash
# Linux Server Manager for Android (proot-distro manager)
# Mobile-optimized, modular management tool and control center for Termux

set -e

# Determine the base directory of this script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export BASE_DIR
export LIB_PATH="$BASE_DIR/lib"

# Source modular libraries
# shellcheck source=/dev/null
source "$LIB_PATH/colors.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/system.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/network.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/distro.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/users.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/ssh.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/vnc.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/ui.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/diagnostics.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/config.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/services.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/logs.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/wizard.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/recommendations.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/packages.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/backup.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/root.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/network.sh"
# shellcheck source=/dev/null
source "$LIB_PATH/docker.sh"

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_DIR="$PREFIX/etc/linux-on-android"
mkdir -p "$CONFIG_DIR"

detect_environment
load_config

print_usage() {
    echo "Usage: ./linux-on-android.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --status               Show overall system and container status"
    echo "  --ip, --network        Show device IP and SSH/VNC connection URLs"
    echo "  --connect-ssh          Connect to a remote SSH server (client mode)"
    echo "  --docker               Open Native Rooted Docker Hub"
    echo "  --start-docker         Start dockerd daemon"
    echo "  --stop-docker          Stop dockerd daemon"
    echo "  --auto-install [dist]  Non-interactively install a distribution (e.g. debian)"
    echo "  --wizard               Launch interactive First-Run / Distro Setup Wizard"
    echo "  --recommend            Show hardware-tailored recommendations"
    echo "  --services             Manage background services (SSH, VNC, etc.)"
    echo "  --logs                 Open unified log viewer"
    echo "  --doctor               Run comprehensive system diagnostics"
    echo "  --root                 Open Root Hub & Native Chroot Manager"
    echo "  --chroot [dist]        Direct native chroot login without PRoot overhead"
    echo "  --start-vnc            Start VNC server for installed distribution"
    echo "  --stop-vnc             Stop VNC server for installed distribution"
    echo "  --start-ssh            Start SSH server for installed distribution"
    echo "  --stop-ssh             Stop SSH server for installed distribution"
    echo "  --help, -h             Show this help message"
}

# CLI routing
if [[ $# -gt 0 ]]; then
    case "$1" in
        --status)
            draw_header "Status Overview"
            CURRENT_DISTRO=$(get_installed_distro)
            draw_status_bar "$CURRENT_DISTRO"
            show_all_services_status
            hardware_summary
            exit 0
            ;;
        --ip|--network)
            show_network_info
            exit 0
            ;;
        --connect-ssh)
            connect_to_remote_ssh
            exit 0
            ;;
        --docker)
            docker_menu
            exit 0
            ;;
        --start-docker)
            start_dockerd
            exit 0
            ;;
        --stop-docker)
            stop_dockerd
            exit 0
            ;;
        --auto-install)
            DISTRO="${2:-debian}"
            echo "Auto-installing $DISTRO..."
            proot-distro install "$DISTRO"
            exit 0
            ;;
        --wizard)
            wizard_menu
            exit 0
            ;;
        --recommend)
            show_all_recommendations
            exit 0
            ;;
        --services)
            service_menu
            exit 0
            ;;
        --logs)
            view_logs
            exit 0
            ;;
        --doctor)
            run_diagnostics
            exit 0
            ;;
        --root)
            CURRENT_DISTRO=$(get_installed_distro)
            root_menu "$CURRENT_DISTRO"
            exit 0
            ;;
        --chroot)
            DISTRO="${2:-$(get_installed_distro)}"
            if [[ -n "$DISTRO" ]]; then
                chroot_login "$DISTRO"
            else
                echo "No distribution installed."
            fi
            exit 0
            ;;
        --start-vnc)
            CURRENT_DISTRO=$(get_installed_distro)
            [[ -n "$CURRENT_DISTRO" ]] && start_vnc "$CURRENT_DISTRO"
            exit 0
            ;;
        --stop-vnc)
            CURRENT_DISTRO=$(get_installed_distro)
            [[ -n "$CURRENT_DISTRO" ]] && stop_vnc "$CURRENT_DISTRO"
            exit 0
            ;;
        --start-ssh)
            CURRENT_DISTRO=$(get_installed_distro)
            [[ -n "$CURRENT_DISTRO" ]] && start_ssh "$CURRENT_DISTRO"
            exit 0
            ;;
        --stop-ssh)
            CURRENT_DISTRO=$(get_installed_distro)
            [[ -n "$CURRENT_DISTRO" ]] && stop_ssh "$CURRENT_DISTRO"
            exit 0
            ;;
        --help|-h)
            print_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
    esac
fi

main_menu() {
    while true; do
        draw_header "Linux Server Manager"
        CURRENT_DISTRO=$(get_installed_distro)
        draw_status_bar "$CURRENT_DISTRO"
        
        draw_card "Control Center" \
            "${YELLOW} 1)${RESET} First-Run / Setup Wizard" \
            "${YELLOW} 2)${RESET} Install Linux Distribution" \
            "${YELLOW} 3)${RESET} Launch / Login to Linux" \
            "${YELLOW} 4)${RESET} Service Management (SSH/VNC)" \
            "${YELLOW} 5)${RESET} Network & Remote Access Hub (IP/SSH/VNC)" \
            "${YELLOW} 6)${RESET} Hardware Recommendations" \
            "${YELLOW} 7)${RESET} Package Stacks & Software" \
            "${YELLOW} 8)${RESET} Backup & Restore Snapshots" \
            "${YELLOW} 9)${RESET} Root Hub & Native Chroot" \
            "${YELLOW}10)${RESET} Rooted Docker Engine (dockerd)" \
            "${YELLOW}11)${RESET} View Logs & Telemetry" \
            "${YELLOW}12)${RESET} System Diagnostics & Doctor" \
            "${YELLOW}13)${RESET} Uninstall Distribution" \
            "${YELLOW}14)${RESET} Uninstall ALL Distributions" \
            "${YELLOW}15)${RESET} Exit (or '0' / 'q')"
        
        echo ""
        menu_prompt
        read -r CHOICE

        case "$CHOICE" in
            1) wizard_menu ;;
            2) 
                install_linux
                echo ""
                read -rp "Press Enter to return to main menu..." _
                ;;
            3) 
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    login_distro "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution currently installed.${RESET}"
                    echo ""
                    read -rp "Press Enter to return to main menu..." _
                fi
                ;;
            4) service_menu ;;
            5) network_menu ;;
            6) show_all_recommendations ;;
            7) 
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    package_menu "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                    echo ""
                    read -rp "Press Enter to return to main menu..." _
                fi
                ;;
            8)
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    backup_menu "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                    echo ""
                    read -rp "Press Enter to return to main menu..." _
                fi
                ;;
            9)
                root_menu "$CURRENT_DISTRO"
                ;;
            10)
                docker_menu
                ;;
            11) view_logs ;;
            12) run_diagnostics ;;
            13) 
                uninstall_one
                echo ""
                read -rp "Press Enter to return to main menu..." _
                ;;
            14) 
                uninstall_all
                echo ""
                read -rp "Press Enter to return to main menu..." _
                ;;
            15|0|[qQ]|[eE][xX][iI][tT]) 
                echo -e "${GREEN}Goodbye!${RESET}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Invalid choice.${RESET}"
                sleep 1
                ;;
        esac
    done
}

install_linux() {
    draw_header "Linux Installation"
    
    echo -e "${BLUE}Updating Termux packages...${RESET}"
    apt update && apt upgrade -y

    if ! command -v proot-distro &> /dev/null; then
        echo -e "${BLUE}Installing proot-distro...${RESET}"
        apt install -y proot-distro
    fi

    draw_card "Available Distributions" \
        "Run 'proot-distro list' for full list" \
        "Popular: debian, ubuntu, alpine, fedora, arch"
    echo ""
    proot-distro list | head -20
    echo ""

    read -rp "${CYAN}Enter distro to install [debian] (or 'b' to cancel):${RESET} " DISTRO
    if [[ "$DISTRO" =~ ^(0|[bB]|[qQ]|back|exit)$ ]]; then
        echo -e "${YELLOW}Installation cancelled.${RESET}"
        return 0
    fi
    DISTRO="${DISTRO:-debian}"

    read -rp "${CYAN}Enter username to create [user]:${RESET} " USERNAME
    USERNAME="${USERNAME:-user}"

    read -rp "${CYAN}Install LXDE desktop? [y/N]:${RESET} " INSTALL_GUI
    INSTALL_GUI="${INSTALL_GUI:-N}"

    read -rp "${CYAN}VNC resolution [1920x1080]:${RESET} " RES
    RES="${RES:-1920x1080}"

    read -rp "${CYAN}Enter VNC password [1234]:${RESET} " VNC_PASSWD
    VNC_PASSWD="${VNC_PASSWD:-1234}"

    echo ""
    draw_card "Configuration Summary" \
        "${YELLOW}Distro:${RESET}        $DISTRO" \
        "${YELLOW}Username:${RESET}      $USERNAME" \
        "${YELLOW}Install GUI:${RESET}   $INSTALL_GUI" \
        "${YELLOW}Resolution:${RESET}    $RES" \
        "${YELLOW}VNC Password:${RESET}  $VNC_PASSWD"
    echo ""
    
    read -rp "${GREEN}Proceed with installation? [y/N]:${RESET} " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        echo -e "${RED}Installation cancelled.${RESET}"
        return 0
    fi

    echo -e "${BLUE}Installing $DISTRO...${RESET}"
    proot-distro install "$DISTRO"

    echo -e "${BLUE}Configuring inside $DISTRO...${RESET}"

    proot-distro login "$DISTRO" -- bash -lc "
apt update && apt upgrade -y

apt install -y sudo passwd

useradd -m -s /bin/bash \"$USERNAME\"
passwd -d \"$USERNAME\" 2>/dev/null || true

echo \"$USERNAME ALL=(ALL:ALL) NOPASSWD: ALL\" > /etc/sudoers.d/\"$USERNAME\"
chmod 440 /etc/sudoers.d/\"$USERNAME\"

if [[ \"$INSTALL_GUI\" =~ ^[yY]$ ]]; then
    apt install -y lxde tightvncserver
fi
"

    if [[ "$INSTALL_GUI" =~ ^[yY]$ ]]; then
    proot-distro login "$DISTRO" -- bash -lc "
if ! command -v vncserver >/dev/null; then
    echo -e '${RED}VNC installation failed. Skipping setup.${RESET}'
    exit 0
fi

echo -e '${BLUE}Cleaning stale VNC lock files...${RESET}'
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

sudo -u \"$USERNAME\" bash -lc '
mkdir -p /home/\"$USERNAME\"/.vnc
echo \"$VNC_PASSWD\" | vncpasswd -f > /home/\"$USERNAME\"/.vnc/passwd
chmod 600 /home/\"$USERNAME\"/.vnc/passwd

cat > /home/\"$USERNAME\"/.vnc/xstartup <<EOS
#!/bin/bash
xrdb \$HOME/.Xresources
exec startlxde &
EOS

chmod +x /home/\"$USERNAME\"/.vnc/xstartup

vncserver -geometry $RES :1 || true
vncserver -kill :1 || true
'
"
    fi

    echo -e "${BLUE}Saving config...${RESET}"
    cat > "$CONFIG_DIR/$DISTRO.conf" <<EOF
DISTRO=$DISTRO
USERNAME=$USERNAME
GUI=$INSTALL_GUI
RESOLUTION=$RES
VNC_PASSWD=$VNC_PASSWD
EOF

    echo ""
    draw_card "Installation Complete!" \
        "${CYAN}Login:${RESET}        proot-distro login $DISTRO --" \
        "${CYAN}Switch User:${RESET}  su - $USERNAME" \
        "${CYAN}Start VNC:${RESET}    linux-on-android --start-vnc" \
        "${CYAN}Stop VNC:${RESET}     linux-on-android --stop-vnc" \
        "${CYAN}VNC Pass:${RESET}     $VNC_PASSWD"
}

uninstall_one() {
    local conf_files=("$CONFIG_DIR"/*.conf)
    if [[ ! -e "${conf_files[0]}" ]]; then
        echo -e "${RED}No installed distros found.${RESET}"
        return
    fi

    echo -e "${CYAN}Installed distros:${RESET}"
    for file in "${conf_files[@]}"; do
        [[ -e "$file" ]] && basename "$file" .conf
    done

    read -rp "Enter distro to uninstall: " DISTRO

    CONFIG_FILE="$CONFIG_DIR/$DISTRO.conf"

    if [[ -z "$DISTRO" || ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}No config found for $DISTRO${RESET}"
        return 1
    fi

    read -rp "Remove distro '$DISTRO'? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}Uninstall cancelled.${RESET}"
        return 0
    fi

    echo -e "${BLUE}Stopping any running VNC sessions...${RESET}"
    proot-distro login "$DISTRO" -- vncserver -kill :1 2>/dev/null || true

    echo -e "${BLUE}Removing $DISTRO...${RESET}"
    proot-distro remove "$DISTRO" || true
    rm -f "$CONFIG_FILE"

    echo -e "${GREEN}Removed $DISTRO${RESET}"
}

uninstall_all() {
    local conf_files=("$CONFIG_DIR"/*.conf)
    if [[ ! -e "${conf_files[0]}" ]]; then
        echo -e "${RED}No installed distros found.${RESET}"
        return
    fi

    echo -e "${RED}${BOLD}This will remove ALL installed distros and configs.${RESET}"
    read -rp "Are you sure? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}Uninstall cancelled.${RESET}"
        return 0
    fi

    for FILE in "${conf_files[@]}"; do
        [[ -e "$FILE" ]] || continue
        DISTRO=""
        # shellcheck source=/dev/null
        source "$FILE"
        if [[ -n "$DISTRO" ]]; then
            echo -e "${BLUE}Stopping VNC and removing $DISTRO...${RESET}"
            proot-distro login "$DISTRO" -- vncserver -kill :1 2>/dev/null || true
            proot-distro remove "$DISTRO" || true
        fi
        rm -f "$FILE"
    done

    echo -e "${GREEN}All distros removed.${RESET}"

    read -rp "Remove proot-distro as well? (y/N): " REMOVE_PROOT
    if [[ "$REMOVE_PROOT" =~ ^[yY]$ ]]; then
        apt remove -y proot-distro || true
    fi

    echo -e "${GREEN}Cleanup complete.${RESET}"
}

main_menu

