#!/usr/bin/env bash
# Linux Server Manager for Android (proot-distro manager)
# Mobile-optimized, modular management tool for Termux

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

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
CONFIG_DIR="$PREFIX/etc/linux-on-android"
mkdir -p "$CONFIG_DIR"

detect_environment

main_menu() {
    while true; do
        draw_header "Linux Server Manager"
        CURRENT_DISTRO=$(get_installed_distro)
        draw_status_bar "$CURRENT_DISTRO"
        
        echo -e "${YELLOW}1)${RESET} Install Linux Distribution"
        echo -e "${YELLOW}2)${RESET} Uninstall a Distribution"
        echo -e "${YELLOW}3)${RESET} Uninstall ALL Distributions"
        echo -e "${YELLOW}4)${RESET} Launch / Login to Linux"
        echo -e "${YELLOW}5)${RESET} Manage Desktop / VNC"
        echo -e "${YELLOW}6)${RESET} Manage SSH Server"
        echo -e "${YELLOW}7)${RESET} System Diagnostics"
        echo -e "${YELLOW}8)${RESET} Exit"
        echo ""
        menu_prompt
        read -r CHOICE

        case "$CHOICE" in
            1) install_linux ;;
            2) uninstall_one ;;
            3) uninstall_all ;;
            4) 
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    login_distro "$CURRENT_DISTRO"
                else
                    echo -e "${RED}No distribution currently installed.${RESET}"
                fi
                ;;
            5)
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    echo "1) Start VNC"
                    echo "2) Stop VNC"
                    echo "3) Restart VNC"
                    read -rp "Choice: " VNC_OPT
                    case "$VNC_OPT" in
                        1) start_vnc "$CURRENT_DISTRO" ;;
                        2) stop_vnc "$CURRENT_DISTRO" ;;
                        3) restart_vnc "$CURRENT_DISTRO" ;;
                    esac
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                fi
                ;;
            6)
                if [[ -n "$CURRENT_DISTRO" ]]; then
                    echo "1) Start SSH"
                    echo "2) Stop SSH"
                    read -rp "Choice: " SSH_OPT
                    case "$SSH_OPT" in
                        1) start_ssh "$CURRENT_DISTRO" ;;
                        2) stop_ssh "$CURRENT_DISTRO" ;;
                    esac
                else
                    echo -e "${RED}No distribution installed.${RESET}"
                fi
                ;;
            7) run_diagnostics ;;
            8) echo -e "${GREEN}Goodbye!${RESET}"; exit 0 ;;
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

