#!/bin/bash
# Smart recommendations engine for Linux-on-Android
# Provides hardware-based recommendations for distro and desktop selections

# Hardware thresholds (in MB for RAM, GB for storage)
MIN_RAM_LIGHT=512
MIN_RAM_MEDIUM=1024
MIN_RAM_HEAVY=2048

MIN_STORAGE_LIGHT=4
MIN_STORAGE_MEDIUM=8
MIN_STORAGE_HEAVY=16

# Get system RAM in MB
get_system_ram() {
    local ram_kb=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
    echo $((ram_kb / 1024))
}

# Get available storage in GB
get_available_storage() {
    local storage_kb=$(df -k "$HOME" 2>/dev/null | tail -1 | awk '{print $4}')
    echo $((storage_kb / 1024 / 1024))
}

# Get CPU cores
get_cpu_cores() {
    nproc 2>/dev/null || echo 1
}

# Get CPU architecture
get_cpu_arch() {
    uname -m 2>/dev/null || echo "unknown"
}

# Classify device capability
classify_device() {
    local ram=$(get_system_ram)
    local storage=$(get_available_storage)
    local cores=$(get_cpu_cores)
    
    if [[ $ram -lt $MIN_RAM_LIGHT || $storage -lt $MIN_STORAGE_LIGHT ]]; then
        echo "minimal"
    elif [[ $ram -lt $MIN_RAM_MEDIUM || $storage -lt $MIN_STORAGE_MEDIUM ]]; then
        echo "light"
    elif [[ $ram -lt $MIN_RAM_HEAVY || $storage -lt $MIN_STORAGE_HEAVY ]]; then
        echo "medium"
    else
        echo "powerful"
    fi
}

# Recommend distribution based on hardware
recommend_distro() {
    local device_class=$(classify_device)
    local ram=$(get_system_ram)
    local cores=$(get_cpu_cores)
    
    echo ""
    echo "=== Distro Recommendations ==="
    echo ""
    echo "Device Analysis:"
    echo "  RAM: ${ram}MB"
    echo "  Storage: $(get_available_storage)GB"
    echo "  CPU Cores: $cores"
    echo "  Classification: $device_class"
    echo ""
    
    case "$device_class" in
        minimal)
            echo "Recommended: Alpine Linux"
            echo "  • Extremely lightweight (~5MB base)"
            echo "  • Perfect for devices with limited resources"
            echo "  • Uses musl libc for smaller footprint"
            echo ""
            echo "Alternative: Debian (minimal install)"
            echo "  • Stable and well-supported"
            echo "  • Can be trimmed down significantly"
            ;;
        light)
            echo "Recommended: Debian"
            echo "  • Balanced performance and compatibility"
            echo "  • Excellent package availability"
            echo "  • Stable and well-documented"
            echo ""
            echo "Alternative: Alpine Linux"
            echo "  • Still great for performance"
            echo "  • Security-focused design"
            ;;
        medium)
            echo "Recommended: Ubuntu"
            echo "  • Good balance of features and performance"
            echo "  • Wide community support"
            echo "  • Regular updates"
            echo ""
            echo "Alternative: Debian"
            echo "  • More stable, less frequent updates"
            echo "  • Larger package repository"
            ;;
        powerful)
            echo "Recommended: Ubuntu or Fedora"
            echo "  • Full-featured desktop experience"
            echo "  • Modern software stack"
            echo "  • Good for development work"
            echo ""
            echo "Alternative: Arch Linux"
            echo "  • Rolling release, bleeding edge"
            echo "  • Complete customization"
            echo "  • Requires more maintenance"
            ;;
    esac
    echo ""
}

# Recommend desktop environment
recommend_desktop() {
    local device_class=$(classify_device)
    local ram=$(get_system_ram)
    
    echo ""
    echo "=== Desktop Recommendations ==="
    echo ""
    
    case "$device_class" in
        minimal)
            echo "Recommended: No Desktop (Headless)"
            echo "  • Conserve all resources for services"
            echo "  • Use SSH for remote access"
            echo ""
            echo "If GUI needed: LXDE"
            echo "  • Extremely lightweight"
            echo "  • Minimal dependencies"
            ;;
        light)
            echo "Recommended: LXDE"
            echo "  • Lightweight and responsive"
            echo "  • Low memory footprint"
            echo "  • Classic desktop experience"
            echo ""
            echo "Alternative: XFCE"
            echo "  • Slightly more features"
            echo "  • Still very efficient"
            ;;
        medium)
            echo "Recommended: XFCE"
            echo "  • Good balance of features and performance"
            echo "  • Modern look and feel"
            echo "  • Customizable"
            echo ""
            echo "Alternative: LXDE"
            echo "  • If you prefer maximum performance"
            ;;
        powerful)
            echo "Recommended: GNOME or XFCE"
            echo "  • GNOME: Full modern desktop experience"
            echo "  • XFCE: Traditional desktop with customization"
            echo ""
            echo "Alternative: LXDE"
            echo "  • If you prefer lightweight environments"
            ;;
    esac
    echo ""
}

# Recommend services based on hardware
recommend_services() {
    local device_class=$(classify_device)
    local ram=$(get_system_ram)
    
    echo ""
    echo "=== Service Recommendations ==="
    echo ""
    
    case "$device_class" in
        minimal)
            echo "Recommended Services:"
            echo "  • SSH only (for remote management)"
            echo "  • Avoid VNC to conserve memory"
            echo ""
            echo "Optional: Lightweight web server (nginx)"
            ;;
        light)
            echo "Recommended Services:"
            echo "  • SSH (essential)"
            echo "  • VNC (for remote desktop, if needed)"
            echo ""
            echo "Caution: Running both may impact performance"
            ;;
        medium|powerful)
            echo "Recommended Services:"
            echo "  • SSH (essential for remote access)"
            echo "  • VNC (for graphical remote access)"
            echo "  • Custom services as needed"
            echo ""
            echo "Your device can handle multiple services comfortably"
            ;;
    esac
    echo ""
}

# Show comprehensive recommendations
show_all_recommendations() {
    echo ""
    echo "╔════════════════════════════════════════════╗"
    echo "║     Hardware-Based Recommendations         ║"
    echo "╚════════════════════════════════════════════╝"
    
    recommend_distro
    recommend_desktop
    recommend_services
    
    echo "Press Enter to return to menu..."
    read -r
}

# Quick hardware summary
hardware_summary() {
    local ram=$(get_system_ram)
    local storage=$(get_available_storage)
    local cores=$(get_cpu_cores)
    local arch=$(get_cpu_arch)
    local device_class=$(classify_device)
    
    echo ""
    echo "=== Hardware Summary ==="
    echo ""
    echo "Architecture: $arch"
    echo "CPU Cores: $cores"
    echo "RAM: ${ram}MB"
    echo "Available Storage: ${storage}GB"
    echo "Device Class: $device_class"
    echo ""
}
