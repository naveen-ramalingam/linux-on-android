#!/bin/bash
# Configuration management for Linux-on-Android
# Handles settings like theme, compact mode, default distro, ports, etc.

# Default configuration
DEFAULT_THEME="dark"
DEFAULT_COMPACT_MODE=false
DEFAULT_DEFAULT_DISTRO="debian"
DEFAULT_PORT=8080

# Load configuration from environment or defaults
CONFIG_FILE="${HOME}/.linux-on-android.conf"

# Function to load configuration
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
    fi
}

# Function to save configuration
save_config() {
    echo "THEME=${DEFAULT_THEME}" >> "$CONFIG_FILE"
    echo "COMPACT_MODE=${DEFAULT_COMPACT_MODE}" >> "$CONFIG_FILE"
    echo "DEFAULT_DISTRO=${DEFAULT_DEFAULT_DISTRO}" >> "$CONFIG_FILE"
    echo "DEFAULT_PORT=${DEFAULT_PORT}" >> "$CONFIG_FILE"
}

# Print current configuration
print_config() {
    echo "=== Linux-on-Android Configuration ==="
    echo "Theme: $(grep THEME "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')"
    echo "Compact Mode: $(grep COMPACT_MODE "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')"
    echo "Default Distro: $(grep DEFAULT_DEFAULT_DISTRO "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')"
    echo "Default Port: $(grep DEFAULT_PORT "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' ')"
}

# Apply theme
theme_apply() {
    case "$THEME" in
        "light")
            export TERM_COLORS="\033[0;37m\033[1;36m\033[0m"  # Blue, Cyan, White
            ;;
        "dark")
            export TERM_COLORS="\033[0;30m\033[1;35m\033[0m"  # Dark blue, Magenta, White
            ;;
        "auto")
            # Auto-detect based on system theme
            ;;
        *)
            echo "Unknown theme: $THEME, falling back to light"
            export TERM_COLORS="\033[0;37m\033[1;36m\033[0m"
            ;;
    esac
}

# Apply compact mode
apply_compact_mode() {
    if [[ "$COMPACT_MODE" == "true" ]]; then
        export COLOR_ACCENT="#4CAF50"  # Green accent for compact mode
        export SCREEN_BORDER="#90E0EF"  # Light blue border
        echo "Compact mode enabled"
    else
        export COLOR_ACCENT="#2196F3"  # Blue accent
        export SCREEN_BORDER="#E3F2FD"  # Light blue border
        echo "Normal mode"
    fi
}

# Set default distro
set_default_distro() {
    local distro="${DEFAULT_DEFAULT_DISTRO}"
    if [[ -n "$DISTRO" ]]; then
        distro="$DISTRO"
    fi
    export DEFAULT_DISTRO="$distro"
    echo "Default distro set to: $distro"
}

# Set port
set_port() {
    local port="${DEFAULT_PORT}"
    if [[ -n "$PORT" ]]; then
        port="$PORT"
    fi
    export DEFAULT_PORT="$port"
    echo "Default port set to: $port"
}

# Export current settings
export SETTINGS
