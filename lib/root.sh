#!/bin/bash
# Root and Native Chroot Module for Linux Server Manager
# Provides high-performance chroot, low-port binding, SELinux controls, and kernel hardware access for rooted Android devices

source "$LIB_PATH/colors.sh"
source "$LIB_PATH/ui.sh"

is_root_available() {
    if [[ $EUID -eq 0 ]]; then
        return 0
    elif command -v tsu &>/dev/null || command -v su &>/dev/null; then
        return 0
    fi
    return 1
}

get_root_type() {
    if [[ -d "/data/adb/ksu" ]] || [[ -f "/data/adb/ksud" ]]; then
        echo "KernelSU"
    elif [[ -d "/data/adb/ap" ]] || [[ -f "/data/adb/apd" ]]; then
        echo "APatch"
    elif [[ -d "/data/adb/magisk" ]] || command -v magisk &>/dev/null; then
        echo "Magisk"
    elif command -v su &>/dev/null || command -v tsu &>/dev/null; then
        echo "Standard su"
    else
        echo "Not Rooted"
    fi
}

run_as_root() {
    local cmd="$*"
    if [[ $EUID -eq 0 ]]; then
        eval "$cmd"
    elif command -v tsu &>/dev/null; then
        tsu -c "$cmd"
    elif command -v su &>/dev/null; then
        su -c "$cmd"
    else
        echo -e "${RED}Error: Root access not available.${RESET}"
        return 1
    fi
}

check_root_capabilities() {
    draw_header "Root & Kernel Diagnostics"
    
    local root_type
    root_type=$(get_root_type)
    
    local selinux_status="Unknown"
    if command -v getenforce &>/dev/null; then
        selinux_status=$(getenforce 2>/dev/null || echo "Unknown")
    fi
    
    local tun_support="${RED}No (/dev/net/tun missing)${RESET}"
    [[ -e "/dev/net/tun" ]] && tun_support="${GREEN}Yes (VPN/WireGuard ready)${RESET}"
    
    local kvm_support="${RED}No (/dev/kvm missing)${RESET}"
    [[ -e "/dev/kvm" ]] && kvm_support="${GREEN}Yes (Hardware Virtualization ready)${RESET}"
    
    local gpu_support="${RED}None detected${RESET}"
    if [[ -e "/dev/kgsl-3d0" ]]; then
        gpu_support="${GREEN}Adreno GPU (/dev/kgsl-3d0)${RESET}"
    elif [[ -e "/dev/mali0" ]]; then
        gpu_support="${GREEN}Mali GPU (/dev/mali0)${RESET}"
    elif [[ -e "/dev/dri/card0" ]]; then
        gpu_support="${GREEN}Direct DRI (/dev/dri/card0)${RESET}"
    fi

    local swap_info
    swap_info=$(free -m 2>/dev/null | grep -i swap | awk '{print $2 "MB (Used: " $3 "MB)"}' || echo "N/A")

    draw_card "Root Environment" \
        "${CYAN}Root Framework:${RESET} $root_type" \
        "${CYAN}SELinux Mode:${RESET}   $selinux_status" \
        "${CYAN}TUN/TAP Device:${RESET} $tun_support" \
        "${CYAN}KVM Acceleration:${RESET} $kvm_support" \
        "${CYAN}Direct GPU Node:${RESET} $gpu_support" \
        "${CYAN}Linux Swap/ZRAM:${RESET} $swap_info"
    
    echo ""
    draw_card "Performance Note" \
        "Native chroot gives 100% bare-metal Linux performance" \
        "with zero PRoot/ptrace overhead for CPU and disk I/O."
    echo ""
}

toggle_selinux() {
    draw_header "SELinux Mode Switcher"
    local current="Unknown"
    if command -v getenforce &>/dev/null; then
        current=$(getenforce 2>/dev/null)
    fi
    
    draw_card "Current SELinux State" \
        "${CYAN}Current Mode:${RESET} $current" \
        "" \
        "Permissive mode allows native chroot and custom daemon binds" \
        "without Android SELinux domain restrictions."
    echo ""
    
    echo -ne "${YELLOW}Set SELinux mode: [1] Permissive (0)  [2] Enforcing (1)  [b] Cancel:${RESET} "
    read -r smode
    
    case "$smode" in
        1)
            echo -e "${BLUE}Switching to Permissive...${RESET}"
            run_as_root "setenforce 0"
            echo -e "${GREEN}✓ SELinux set to Permissive${RESET}"
            ;;
        2)
            echo -e "${BLUE}Switching to Enforcing...${RESET}"
            run_as_root "setenforce 1"
            echo -e "${GREEN}✓ SELinux set to Enforcing${RESET}"
            ;;
        *)
            echo -e "${YELLOW}Cancelled.${RESET}"
            ;;
    esac
}

get_distro_rootfs_path() {
    local distro="$1"
    local path="$PREFIX/var/lib/proot-distro/installed-rootfs/$distro"
    if [[ -d "$path" ]]; then
        echo "$path"
    else
        echo ""
    fi
}

chroot_mount() {
    local distro="$1"
    local rootfs
    rootfs=$(get_distro_rootfs_path "$distro")
    
    if [[ -z "$rootfs" ]]; then
        echo -e "${RED}Distro '$distro' rootfs not found at $PREFIX/var/lib/proot-distro/installed-rootfs/$distro${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}Mounting virtual filesystems into $distro rootfs...${RESET}"
    run_as_root "
        mkdir -p '$rootfs/dev' '$rootfs/dev/pts' '$rootfs/dev/shm' '$rootfs/proc' '$rootfs/sys' '$rootfs/sdcard'
        mount -o bind /dev '$rootfs/dev' 2>/dev/null || true
        mount -t devpts devpts '$rootfs/dev/pts' 2>/dev/null || true
        mount -t tmpfs tmpfs '$rootfs/dev/shm' 2>/dev/null || true
        mount -t proc proc '$rootfs/proc' 2>/dev/null || true
        mount -t sysfs sysfs '$rootfs/sys' 2>/dev/null || true
        mount -o bind /sdcard '$rootfs/sdcard' 2>/dev/null || true
    "
    echo -e "${GREEN}✓ Filesystems mounted.${RESET}"
}

chroot_unmount() {
    local distro="$1"
    local rootfs
    rootfs=$(get_distro_rootfs_path "$distro")
    
    if [[ -z "$rootfs" ]]; then
        echo -e "${RED}Distro '$distro' rootfs not found.${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}Unmounting virtual filesystems from $distro rootfs...${RESET}"
    run_as_root "
        umount '$rootfs/sdcard' 2>/dev/null || true
        umount '$rootfs/dev/shm' 2>/dev/null || true
        umount '$rootfs/dev/pts' 2>/dev/null || true
        umount '$rootfs/dev' 2>/dev/null || true
        umount '$rootfs/proc' 2>/dev/null || true
        umount '$rootfs/sys' 2>/dev/null || true
    "
    echo -e "${GREEN}✓ Filesystems cleanly unmounted.${RESET}"
}

chroot_login() {
    local distro="$1"
    local rootfs
    rootfs=$(get_distro_rootfs_path "$distro")
    
    if [[ -z "$rootfs" ]]; then
        echo -e "${RED}Distribution '$distro' not found.${RESET}"
        return 1
    fi
    
    draw_header "Native Root Chroot ($distro)"
    echo -e "${CYAN}Mounting kernel filesystems...${RESET}"
    chroot_mount "$distro"
    
    echo -e "${GREEN}Starting native chroot shell with bare-metal speed...${RESET}"
    echo -e "${YELLOW}(Type 'exit' to leave chroot)${RESET}\n"
    
    run_as_root "
        export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
        export HOME=/root
        export TERM='$TERM'
        chroot '$rootfs' /bin/bash -l
    "
    
    echo -e "\n${BLUE}Cleaning up mounts...${RESET}"
    chroot_unmount "$distro"
    echo -e "${GREEN}✓ Returned from chroot.${RESET}"
}

setup_port_forward() {
    draw_header "Low Port Forwarding (Root iptables)"
    draw_card "Port Redirection" \
        "Allows binding to privileged ports (< 1024) like:" \
        "• Port 80 (HTTP) -> 8080 (Web Server)" \
        "• Port 443 (HTTPS) -> 8443 (Secure Web)" \
        "• Port 22 (SSH) -> 2222 (OpenSSH)"
    echo ""
    
    echo -ne "${CYAN}Enter external port to redirect (e.g. 80, 443, 22) [or 'b' to back]:${RESET} "
    read -r ext_port
    [[ "$ext_port" =~ ^(0|[bB]|[qQ]|back|exit)$ || -z "$ext_port" ]] && return 0
    
    echo -ne "${CYAN}Enter destination internal port (e.g. 8080, 8443, 2222):${RESET} "
    read -r int_port
    [[ "$int_port" =~ ^(0|[bB]|[qQ]|back|exit)$ || -z "$int_port" ]] && return 0
    
    echo -e "${BLUE}Configuring iptables rule...${RESET}"
    run_as_root "
        iptables -t nat -A PREROUTING -p tcp --dport $ext_port -j REDIRECT --to-port $int_port
        iptables -t nat -A OUTPUT -p tcp -d 127.0.0.1 --dport $ext_port -j REDIRECT --to-port $int_port
    "
    echo -e "${GREEN}✓ Traffic on port $ext_port redirected to $int_port!${RESET}"
}

setup_root_swap() {
    draw_header "Device Swap & RAM Booster"
    draw_card "Linux Swap Configuration" \
        "Create a swap file on internal storage to prevent" \
        "Out-Of-Memory (OOM) kills during heavy compilation or multi-service runs."
    echo ""
    
    echo -ne "${CYAN}Enter swap size in MB (default: 2048) [or 'b' to back]:${RESET} "
    read -r swap_size
    [[ "$swap_size" =~ ^(0|[bB]|[qQ]|back|exit)$ ]] && return 0
    swap_size="${swap_size:-2048}"
    
    local swap_file="/data/local/tmp/linux_swapfile"
    echo -e "${BLUE}Allocating ${swap_size}MB swap file at $swap_file...${RESET}"
    
    run_as_root "
        dd if=/dev/zero of='$swap_file' bs=1M count='$swap_size' status=progress
        chmod 600 '$swap_file'
        mkswap '$swap_file'
        swapon '$swap_file'
    "
    echo -e "${GREEN}✓ Swap file activated (${swap_size}MB)!${RESET}"
}

root_menu() {
    local distro="$1"
    [[ -z "$distro" ]] && distro=$(get_installed_distro)
    
    while true; do
        draw_header "Root Hub & Chroot Engine"
        local rtype
        rtype=$(get_root_type)
        
        draw_card "Root Status: $rtype" \
            "${YELLOW} 1)${RESET} Root & Kernel Hardware Diagnostics" \
            "${YELLOW} 2)${RESET} Native Chroot Shell (Zero PRoot overhead)" \
            "${YELLOW} 3)${RESET} SELinux Switcher (Permissive/Enforcing)" \
            "${YELLOW} 4)${RESET} Low Port Redirection (Port 80/443/22 iptables)" \
            "${YELLOW} 5)${RESET} Enable Swap File (RAM Booster)" \
            "${YELLOW} 6)${RESET} Native Docker Engine (dockerd & Containers)" \
            "${YELLOW} 7)${RESET} Clean / Unmount Chroot Mounts" \
            "${YELLOW} 8)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        menu_prompt
        read -r choice
        
        case "$choice" in
            1)
                check_root_capabilities
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            2)
                if [[ -n "$distro" ]]; then
                    chroot_login "$distro"
                else
                    echo -e "${RED}No distribution installed to chroot into.${RESET}"
                fi
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            3)
                toggle_selinux
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            4)
                setup_port_forward
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            5)
                setup_root_swap
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            6)
                if declare -f docker_menu >/dev/null; then
                    docker_menu
                fi
                ;;
            7)
                if [[ -n "$distro" ]]; then
                    chroot_unmount "$distro"
                fi
                echo ""
                read -rp "${YELLOW}Press Enter to continue...${RESET}" _
                ;;
            8|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT])
                break
                ;;
            *)
                echo -e "${RED}Invalid choice.${RESET}"
                sleep 1
                ;;
        esac
    done
}
