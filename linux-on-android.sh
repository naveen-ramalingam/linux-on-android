#!/usr/bin/env bash
# Linux Server Manager for Android (proot-distro manager)
# Mobile-optimized, modular management tool and control center for Termux

set -e

# Determine the base directory of this script
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
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
    echo "  --auto-install [dist]  Non-interactively install a distribution (e.g. debian)"
    echo "  --wizard               Launch interactive First-Run / Distro Setup Wizard"
    echo "  --recommend            Show hardware-tailored recommendations"
    echo "  --services             Manage background services (SSH, VNC, etc.)"
    echo "  --logs                 Open unified log viewer"
    echo "  --doctor               Run comprehensive system diagnostics"
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
        
        echo -e "${YELLOW} 1)${RESET} First-Run / Setup Wizard"
        echo -e "${YELLOW} 2)${RESET} Install Linux Distribution"
        echo -e "${YELLOW} 3)${RESET} Launch / Login to Linux"
        echo -e "${YELLOW} 4)${RESET} Service Management (SSH/VNC)"
        echo -e "${YELLOW} 5)${RESET} Hardware Recommendations"
        echo -e "${YELLOW} 6)${RESET} Package Stacks & Software"
        echo -e "${YELLOW} 7)${RESET} Backup & Restore Snapshots"
        echo -e "${YELLOW} 8)${RESET} View Logs & Telemetry"
        echo -e "${YELLOW} 9)${RESET} System Diagnostics & Doctor"
        echo -e "${YELLOW}10)${RESET} Uninstall Distribution"
        echo -e "${YELLOW}11)${RESET} Uninstall ALL Distributions"
        echo -e "${YELLOW}12)${RESET} Exit"
        
        echo ""
        menu_prompt
        read -r CHOICE

        case "$CHOICE" in
            1) wizard_menu ;;
            2) install_linux ;;
            3) 
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    login_distro "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution currently installed.${RESET}"
                fi
                ;;
            4) service_menu ;;
            5) show_all_recommendations ;;
            6) 
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    package_menu "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                fi
                ;;
            7)
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    backup_menu "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                fi
                ;;
            8) view_logs ;;
            9) run_diagnostics ;;
            10) uninstall_one ;;
            11) uninstall_all ;;
            12) echo -e "${GREEN}Goodbye!${RESET}"; exit 0 ;;
            *) echo -e "${RED}Invalid choice.${RESET}" ;;
        esac
        echo ""
        read -rp "Press Enter to continue..." _
    done
}

install_linux() {
    echo -e "${BLUE}Updating Termux packages...${RESET}"
    apt update && apt upgrade -y

    if ! command -v proot-distro &> /dev/null; then
        echo -e "${BLUE}Installing proot-distro...${RESET}"
        apt install -y proot-distro
    fi

    echo -e "${CYAN}Available distros:${RESET}"
    proot-distro list

    read -rp "Enter distro to install (default: debian): " DISTRO
    DISTRO="${DISTRO:-debian}"

    read -rp "Enter username to create (default: user): " USERNAME
    USERNAME="${USERNAME:-user}"

    read -rp "Install LXDE desktop? (y/N): " INSTALL_GUI
    INSTALL_GUI="${INSTALL_GUI:-N}"

    read -rp "VNC resolution (default 1920x1080): " RES
    RES="${RES:-1920x1080}"

    read -rp "Enter VNC password (default: 1234): " VNC_PASSWD
    VNC_PASSWD="${VNC_PASSWD:-1234}"

    echo ""
    echo -e "${CYAN}${BOLD}=== Confirm Your Configuration ===${RESET}"
    echo -e "${YELLOW}Distro:        ${RESET}$DISTRO"
    echo -e "${YELLOW}Username:      ${RESET}$USERNAME"
    echo -e "${YELLOW}Install GUI:   ${RESET}$INSTALL_GUI"
    echo -e "${YELLOW}Resolution:    ${RESET}$RES"
    echo -e "${YELLOW}VNC Password:  ${RESET}$VNC_PASSWD"
    echo ""
    read -rp "Proceed with installation? (y/N): " CONFIRM
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

    echo -e "${GREEN}${BOLD}=== Installation complete! ===${RESET}"
    echo -e "${CYAN}Login with:${RESET}      proot-distro login $DISTRO --"
    echo -e "${CYAN}Switch user:${RESET}     su - $USERNAME"
    [[ "$INSTALL_GUI" =~ ^[yY]$ ]] && echo -e "${CYAN}Start VNC:${RESET}       vncserver -geometry $RES :1"
    echo -e "${CYAN}Stop VNC:${RESET}        vncserver -kill :1"
    echo -e "${CYAN}VNC password:${RESET}    $VNC_PASSWD"
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

