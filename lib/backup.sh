#!/bin/bash
# Backup and Restore module for Linux Server Manager

# Backup directory
BACKUP_BASE_DIR="${BACKUP_BASE_DIR:-$PREFIX/var/backups/linux-on-android}"
mkdir -p "$BACKUP_BASE_DIR"

backup_distro() {
    local distro="$1"
    local backup_name="${2:-$distro-$(date +%Y%m%d-%H%M%S)}"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if ! is_distro_installed "$distro"; then
        echo -e "${RED}Distro '$distro' is not installed.${RESET}"
        return 1
    fi
    
    echo -e "${BLUE}Creating backup of $distro...${RESET}"
    mkdir -p "$backup_dir"
    
    # Get config
    local config_file="$CONFIG_DIR/$distro.conf"
    if [[ -f "$config_file" ]]; then
        cp "$config_file" "$backup_dir/config.conf"
    fi
    
    # Backup the proot-distro installation
    local distro_path="$PREFIX/var/lib/proot-distro/installed-rootfs/$distro"
    if [[ -d "$distro_path" ]]; then
        echo -e "${BLUE}Archiving filesystem...${RESET}"
        tar -czf "$backup_dir/rootfs.tar.gz" -C "$(dirname "$distro_path")" "$(basename "$distro_path")" 2>/dev/null || {
            echo -e "${YELLOW}Warning: tar encountered issues but continuing...${RESET}"
        }
    fi
    
    # Create manifest
    cat > "$backup_dir/manifest.txt" <<EOF
Backup created: $(date)
Distro: $distro
Architecture: $(get_cpu_arch)
Termux prefix: $PREFIX
EOF
    
    echo -e "${GREEN}Backup created: $backup_dir${RESET}"
    echo -e "${CYAN}Manifest:${RESET}"
    cat "$backup_dir/manifest.txt"
}

restore_distro() {
    local backup_name="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${RED}Backup '$backup_name' not found.${RESET}"
        return 1
    fi
    
    if [[ ! -f "$backup_dir/rootfs.tar.gz" ]]; then
        echo -e "${RED}Invalid backup: missing rootfs.tar.gz${RESET}"
        return 1
    fi
    
    # Read config to get distro name
    local distro=""
    if [[ -f "$backup_dir/config.conf" ]]; then
        # shellcheck source=/dev/null
        source "$backup_dir/config.conf"
    fi
    
    if [[ -z "$distro" ]]; then
        echo -e "${RED}Cannot determine distro name from backup.${RESET}"
        return 1
    fi
    
    echo -e "${YELLOW}This will restore $distro from backup '$backup_name'.${RESET}"
    read -rp "Continue? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}Restore cancelled.${RESET}"
        return 0
    fi
    
    # Remove existing installation if present
    if is_distro_installed "$distro"; then
        echo -e "${BLUE}Removing existing installation...${RESET}"
        proot-distro remove "$distro" || true
    fi
    
    echo -e "${BLUE}Restoring filesystem...${RESET}"
    mkdir -p "$PREFIX/var/lib/proot-distro/installed-rootfs"
    tar -xzf "$backup_dir/rootfs.tar.gz" -C "$PREFIX/var/lib/proot-distro/installed-rootfs"
    
    # Restore config
    if [[ -f "$backup_dir/config.conf" ]]; then
        cp "$backup_dir/config.conf" "$CONFIG_DIR/$distro.conf"
    fi
    
    echo -e "${GREEN}Restore complete for $distro${RESET}"
}

list_backups() {
    draw_header "Available Backups"
    local backups=("$BACKUP_BASE_DIR"/*/)
    if [[ ! -e "${backups[0]}" ]]; then
        draw_card "No Backups" "No saved distro backups found in $BACKUP_BASE_DIR"
        return
    fi
    
    for backup in "${backups[@]}"; do
        local name=$(basename "$backup")
        if [[ -f "$backup/manifest.txt" ]]; then
            local manifest_content
            manifest_content=$(head -n 4 "$backup/manifest.txt")
            draw_card "Backup: $name" "$manifest_content"
        else
            draw_card "Backup: $name" "(No manifest found)"
        fi
        echo ""
    done
}

delete_backup() {
    local backup_name="$1"
    local backup_dir="$BACKUP_BASE_DIR/$backup_name"
    
    if [[ ! -d "$backup_dir" ]]; then
        echo -e "${RED}Backup '$backup_name' not found.${RESET}"
        return 1
    fi
    
    read -rp "Delete backup '$backup_name'? (y/N): " CONFIRM
    if [[ ! "$CONFIRM" =~ ^[yY]$ ]]; then
        echo -e "${YELLOW}Delete cancelled.${RESET}"
        return 0
    fi
    
    rm -rf "$backup_dir"
    echo -e "${GREEN}Backup deleted.${RESET}"
}

backup_menu() {
    local distro="$1"
    while true; do
        draw_header "Backup & Restore ($distro)"
        draw_card "Snapshot Manager" \
            "${YELLOW} 1)${RESET} Create Full Backup" \
            "${YELLOW} 2)${RESET} List Available Backups" \
            "${YELLOW} 3)${RESET} Restore from Backup" \
            "${YELLOW} 4)${RESET} Delete a Backup" \
            "${YELLOW} 5)${RESET} Back to Main Menu"
        echo ""
        menu_prompt
        read -r choice

        case "$choice" in
            1) backup_distro "$distro" ;;
            2) list_backups ;;
            3)
                echo -ne "${CYAN}Enter backup name to restore:${RESET} "
                read -r bname
                [[ -n "$bname" ]] && restore_distro "$bname"
                ;;
            4)
                echo -ne "${CYAN}Enter backup name to delete:${RESET} "
                read -r bname
                [[ -n "$bname" ]] && delete_backup "$bname"
                ;;
            5) break ;;
            *) echo -e "${RED}Invalid choice.${RESET}" ;;
        esac
        echo ""
        read -rp "${YELLOW}Press Enter to continue...${RESET}" _
    done
}

