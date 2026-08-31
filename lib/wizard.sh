#!/bin/bash
# First-Run and Distro Setup Wizard for Linux-on-Android
# Provides guided setup for first-time users and custom distro configuration

# Wizard configuration
WIZARD_CONFIG="${HOME}/.linux-on-android-wizard.conf"

# First-Run Wizard
first_run_wizard() {
    echo ""
    echo "=== First-Run Wizard ==="
    echo ""
    echo "Welcome to Linux-on-Android!"
    echo ""
    
    # Step 1: Welcome and overview
    echo "Step 1: Overview"
    echo "This wizard will help you set up your Linux environment on Android."
    echo "You'll configure your distro, desktop environment, and services."
    echo ""
    read -rp "Press Enter to continue..."
    
    # Step 2: Distro selection
    echo ""
    echo "Step 2: Distro Selection"
    echo "Choose your base Linux distribution:"
    echo "1) Debian (Recommended)"
    echo "2) Ubuntu"
    echo "3) Alpine"
    echo "4) Arch Linux"
    echo "5) Fedora"
    echo "6) Void Linux"
    echo "7) OpenSUSE"
    echo ""
    read -rp "Select distro (1-7): " distro_choice
    
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
    echo ""
    echo "Step 3: Desktop Environment"
    echo "Choose your desktop environment:"
    echo "1) LXDE (Lightweight)"
    echo "2) XFCE (Lightweight)"
    echo "3) GNOME (Full-featured, heavier)"
    echo "4) No Desktop (Headless)"
    echo ""
    read -rp "Select desktop (1-4): " desktop_choice
    
    local desktop
    case "$distro_choice" in
        1) desktop="lxde" ;;
        2) desktop="xfce" ;;
        3) desktop="gnome" ;;
        4) desktop="none" ;;
        *) desktop="lxde" ;;
    esac
    
    # Step 4: Services configuration
    echo ""
    echo "Step 4: Services Configuration"
    echo "Choose services to enable:"
    echo "1) OpenSSH (Remote access)"
    echo "2) TightVNC (Remote desktop)"
    echo "3) Both SSH and VNC"
    echo "4) None"
    echo ""
    read -rp "Select services (1-4): " services_choice
    
    local services
    case "$services_choice" in
        1) services="ssh" ;;
        2) services="vnc" ;;
        3) services="ssh,vnc" ;;
        4) services="none" ;;
        *) services="ssh,vnc" ;;
    esac
    
    # Step 5: Network configuration
    echo ""
    echo "Step 5: Network Configuration"
    read -rp "VNC resolution (default: 1920x1080): " vnc_resolution
    vnc_resolution="${vnc_resolution:-1920x1080}"
    
    read -rp "VNC password (default: 1234): " vnc_password
    vnc_password="${vnc_password:-1234}"
    
    # Step 6: Confirmation
    echo ""
    echo "Step 6: Confirmation"
    echo "Review your configuration:"
    echo "Distribution: $distro"
    echo "Desktop Environment: $desktop"
    echo "Services: $services"
    echo "VNC Resolution: $vnc_resolution"
    echo ""
    read -rp "Confirm? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo ""
        echo "Applying configuration..."
        
        # Create configuration file
        local setup_config="${HOME}/.linux-on-android-setup.conf"
        echo "DISTRO=$distro" > "$setup_config"
        echo "DESKTOP=$desktop" >> "$setup_config"
        echo "SERVICES=$services" >> "$setup_config"
        echo "VNC_RESOLUTION=$vnc_resolution" >> "$setup_config"
        echo "VNC_PASSWORD=$vnc_password" >> "$setup_config"
        
        # Launch installation
        echo "Starting installation..."
        . "/Users/naveenramalingam/Downloads/Linux-on-Android-main/linux-on-android.sh" --auto-install "$distro"
        
        echo ""
        echo "Setup complete! Check the status with: ./linux-on-android.sh --status"
    else
        echo "Setup cancelled"
    fi
}

# Distro Setup Wizard
combo_distro_wizard() {
    echo ""
    echo "=== Distro Setup Wizard ==="
    echo ""
    echo "This wizard helps you create a custom Linux distribution setup."
    echo ""
    
    # Select parent distribution
    echo "Select parent distribution for customization:"
    echo "1) Debian (Base for Ubuntu, etc.)"
    echo "2) Ubuntu (Base for Pop!_OS, etc.)"
    echo "3) Custom"
    echo ""
    read -rp "Select parent (1-3): " parent_choice
    
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
    echo ""
    echo "Select desktop environment:"
    echo "1) LXDE (Lightweight)"
    echo "2) XFCE (Lightweight)"
    echo "3) GNOME (Full-featured)"
    echo "4) None (Server-only)"
    echo ""
    read -rp "Select desktop (1-4): " desktop_choice
    
    local desktop
    case "$desktop_choice" in
        1) desktop="lxde" ;;
        2) desktop="xfce" ;;
        3) desktop="gnome" ;;
        4) desktop="none" ;;
        *) desktop="lxde" ;;
    esac
    
    # Select additional packages
    echo ""
    echo "Select additional packages to install:"
    echo "1) Development tools (gcc, make, etc.)"
    echo "2) Web server (nginx, apache)"
    echo "3) Database (MySQL, PostgreSQL)"
    echo "4) None"
    echo ""
    read -rp "Select packages (1-4, comma-separated): " packages_choice
    
    local packages="$packages_choice"
    case "$packages_choice" in
        4) packages="" ;;
    esac
    
    # Confirm and apply
    echo ""
    echo "Configuration Summary:"
    echo "Parent Distribution: $parent"
    echo "Desktop Environment: $desktop"
    echo "Additional Packages: $packages"
    echo ""
    read -rp "Create this setup? (y/N): " confirm
    
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
        echo ""
        echo "=== Linux-on-Android Wizard ==="
        echo ""
        echo "1) First-Run Wizard"
        echo "2) Distro Setup Wizard"
        echo "3) Back to Main Menu"
        echo ""
        read -rp "Select option: " choice
        
        case "$choice" in
            1)
                first_run_wizard
                break
                ;;
            2)
                combo_distro_wizard
                break
                ;;
            3)
                break
                ;;
            *)
                echo "${RED}Invalid option${RESET}"
                ;;
        esac
    done
}