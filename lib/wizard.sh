#!/bin/bash
# First-Run and Distro Setup Wizard for Linux-on-Android
# Provides guided setup for first-time users and custom distro configuration

# Wizard configuration
WIZARD_CONFIG="${HOME}/.linux-on-android-wizard.conf"

# First-Run Wizard
first_run_wizard() {
    draw_header "First-Run Wizard"
    draw_card "Welcome to Linux-on-Android" \
        "" \
        "This wizard will help you set up your Linux environment" \
        "on Android with optimal configurations." \
        "" \
        "You'll configure your distro, desktop environment, and services."
    echo ""
    read -rp "${YELLOW}Press Enter to continue...${RESET}" _
    
    # Step 2: Distro selection
    draw_header "Distro Selection"
    draw_card "Choose your base distribution" \
        "${YELLOW} 1)${RESET} Debian (Recommended) - Stable & reliable" \
        "${YELLOW} 2)${RESET} Ubuntu - Modern & well-supported" \
        "${YELLOW} 3)${RESET} Alpine - Lightweight (~5MB)" \
        "${YELLOW} 4)${RESET} Arch Linux - Rolling release" \
        "${YELLOW} 5)${RESET} Fedora - Cutting-edge packages" \
        "${YELLOW} 6)${RESET} Void Linux - Independent distro" \
        "${YELLOW} 7)${RESET} OpenSUSE - Enterprise-focused"
    echo ""
    echo -ne "${CYAN}Select distro (1-7):${RESET} "
    read -r distro_choice
    
    local distro
    case "$distro_choice" in
        1) distro="debian" ;;
        2) distro="ubuntu" ;;
        3) distro="alpine" ;;
        4) distro="arch" ;;
        5) distro="fedora" ;;
        6) distro="void" ;;
        7) distro="opensuse" ;;
        *) distro="debian" ;;
    esac
    
    # Step 3: Desktop environment
    draw_header "Desktop Environment"
    draw_card "Choose your desktop environment" \
        "${YELLOW} 1)${RESET} LXDE - Lightweight & responsive" \
        "${YELLOW} 2)${RESET} XFCE - Balance of features & resources" \
        "${YELLOW} 3)${RESET} GNOME - Full modern experience" \
        "${YELLOW} 4)${RESET} No Desktop - Headless/server mode"
    echo ""
    echo -ne "${CYAN}Select desktop (1-4):${RESET} "
    read -r desktop_choice
    
    local desktop
    case "$distro_choice" in
        1) desktop="lxde" ;;
        2) desktop="xfce" ;;
        3) desktop="gnome" ;;
        4) desktop="none" ;;
        *) desktop="lxde" ;;
    esac
    
    # Step 4: Services configuration
    draw_header "Services Configuration"
    draw_card "Choose services to enable" \
        "${YELLOW} 1)${RESET} OpenSSH - Remote terminal access" \
        "${YELLOW} 2)${RESET} TightVNC - Remote desktop access" \
        "${YELLOW} 3)${RESET} Both SSH and VNC" \
        "${YELLOW} 4)${RESET} None - Skip for now"
    echo ""
    echo -ne "${CYAN}Select services (1-4):${RESET} "
    read -r services_choice
    
    local services
    case "$services_choice" in
        1) services="ssh" ;;
        2) services="vnc" ;;
        3) services="ssh,vnc" ;;
        4) services="none" ;;
        *) services="ssh,vnc" ;;
    esac
    
    # Step 5: Network configuration
    draw_header "Network Configuration"
    draw_card "Configure remote access settings" \
        "" \
        "VNC Resolution: 1920x1080 (default)" \
        "VNC Password: (will be set on next screen)"
    echo ""
    echo -ne "${CYAN}VNC resolution (default: 1920x1080):${RESET} "
    read -r vnc_resolution
    vnc_resolution="${vnc_resolution:-1920x1080}"
    
    echo -ne "${CYAN}VNC password (default: 1234):${RESET} "
    read -rs vnc_password
    vnc_password="${vnc_password:-1234}"
    echo ""
    
    # Step 6: Confirmation
    draw_header "Configuration Review"
    draw_card "Confirm your setup" \
        "${CYAN}Distribution:${RESET} $distro" \
        "${CYAN}Desktop Env:${RESET} $desktop" \
        "${CYAN}Services:${RESET} $services" \
        "${CYAN}VNC Resolution:${RESET} $vnc_resolution" \
        "" \
        "Ready to proceed?"
    echo ""
    echo -ne "${YELLOW}Confirm setup? (y/N):${RESET} "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        draw_header "Installation"
        echo -e "${CYAN}Applying configuration...${RESET}"
        
        # Create configuration file
        local setup_config="${HOME}/.linux-on-android-setup.conf"
        echo "DISTRO=$distro" > "$setup_config"
        echo "DESKTOP=$desktop" >> "$setup_config"
        echo "SERVICES=$services" >> "$setup_config"
        echo "VNC_RESOLUTION=$vnc_resolution" >> "$setup_config"
        echo "VNC_PASSWORD=$vnc_password" >> "$setup_config"
        
        # Launch installation
        echo -e "${BLUE}Starting installation of ${BOLD}$distro${RESET}${BLUE}...${RESET}"
        "${BASE_DIR}/linux-on-android.sh" --auto-install "$distro"
        
        draw_card "Success" "Setup complete! Your Linux environment is ready."
        echo -e "${CYAN}Check status with:${RESET} ./linux-on-android.sh --status"
    else
        echo -e "${YELLOW}Setup cancelled${RESET}"
    fi
}

# Distro Setup Wizard
combo_distro_wizard() {
    draw_header "Custom Distro Setup"
    draw_card "Create custom configuration" \
        "" \
        "This wizard helps you create a custom" \
        "Linux distribution setup tailored to your needs."
    echo ""
    
    # Select parent distribution
    draw_card "Select parent distribution" \
        "${YELLOW} 1)${RESET} Debian - Base for Ubuntu & derivatives" \
        "${YELLOW} 2)${RESET} Ubuntu - Modern base system" \
        "${YELLOW} 3)${RESET} Custom - Enter your own"
    echo ""
    echo -ne "${CYAN}Select parent (1-3):${RESET} "
    read -r parent_choice
    
    local parent
    case "$parent_choice" in
        1) parent="debian" ;;
        2) parent="ubuntu" ;;
        3) 
            read -rp "Enter custom distribution name: " parent
            ;;
        *) parent="debian" ;;
    esac
    
    # Select desktop environment
    draw_header "Desktop Environment"
    draw_card "Choose your desktop" \
        "${YELLOW} 1)${RESET} LXDE - Minimal resource usage" \
        "${YELLOW} 2)${RESET} XFCE - Balanced performance" \
        "${YELLOW} 3)${RESET} GNOME - Full-featured modern DE" \
        "${YELLOW} 4)${RESET} None - Server-only (headless)"
    echo ""
    echo -ne "${CYAN}Select desktop (1-4):${RESET} "
    read -r desktop_choice
    
    local desktop
    case "$desktop_choice" in
        1) desktop="lxde" ;;
        2) desktop="xfce" ;;
        3) desktop="gnome" ;;
        4) desktop="none" ;;
        *) desktop="lxde" ;;
    esac
    
    # Select additional packages
    draw_header "Software Stacks"
    draw_card "Select packages to install" \
        "${YELLOW} 1)${RESET} Development (gcc, make, git, etc.)" \
        "${YELLOW} 2)${RESET} Web Server (nginx, apache)" \
        "${YELLOW} 3)${RESET} Database (MySQL, PostgreSQL)" \
        "${YELLOW} 4)${RESET} None - Minimal install"
    echo ""
    echo -ne "${CYAN}Select packages (1-4):${RESET} "
    read -r packages_choice
    
    local packages="$packages_choice"
    case "$packages_choice" in
        4) packages="" ;;
    esac
    
    # Confirm and apply
    draw_header "Review Setup"
    draw_card "Configuration Summary" \
        "${CYAN}Parent Distro:${RESET} $parent" \
        "${CYAN}Desktop:${RESET} $desktop" \
        "${CYAN}Packages:${RESET} ${packages:-None}"
    echo ""
    echo -ne "${YELLOW}Create this setup? (y/N):${RESET} "
    read -r confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Creating custom distro setup..."
        
        # Create custom distro configuration
        local custom_config="${HOME}/.linux-on-android-custom.conf"
        echo "PARENT_DISTRO=$parent" > "$custom_config"
        echo "DESKTOP=$desktop" >> "$custom_config"
        echo "PACKAGES=$packages" >> "$custom_config"
        echo "TIMESTAMP=$(date +%s)" >> "$custom_config"
        
        echo "✓ Custom distro setup created at: $custom_config"
        echo "You can now run the installation with: ./linux-on-android.sh --auto-install $parent"
    else
        echo "Setup cancelled"
    fi
}

# Wizard menu
wizard_menu() {
    while true; do
        draw_header "Linux-on-Android Wizard"
        
        draw_card "Setup Assistants" \
            "${YELLOW} 1)${RESET} First-Run Wizard (Full guided setup)" \
            "${YELLOW} 2)${RESET} Distro Setup Wizard (Hardware-matched)" \
            "${YELLOW} 3)${RESET} Back to Main Menu (or '0' / 'b')"
        echo ""
        read -rp "${CYAN}Select option [1-3, 0/b=back]:${RESET} " choice
        
        case "$choice" in
            1)
                first_run_wizard
                break
                ;;
            2)
                combo_distro_wizard
                break
                ;;
            3|0|[bB]|[qQ]|[bB][aA][cC][kK]|[eE][xX][iI][tT])
                break
                ;;
            *)
                echo -e "${RED}Invalid option${RESET}"
                sleep 1
                ;;
        esac
    done
}