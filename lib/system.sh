#!/bin/bash
# System detection and utilities

detect_environment() {
    export IS_TERMUX=0
    if [[ -d "/data/data/com.termux/files/usr" ]]; then
        export IS_TERMUX=1
    fi
}

get_cpu_arch() {
    uname -m
}

get_battery_status() {
    if [[ "$IS_TERMUX" -eq 1 ]] && command -v termux-battery-status &>/dev/null; then
        termux-battery-status | grep -o '"percentage": [0-9]*' | awk '{print $2}' || echo "N/A"
    else
        echo "N/A"
    fi
}

get_storage_free() {
    df -h /data/data/com.termux/files 2>/dev/null | awk 'NR==2 {print $4}' || df -h . | awk 'NR==2 {print $4}'
}

get_ram_free() {
    free -m 2>/dev/null | awk 'NR==2 {print $4 "MB / " $2 "MB"}' || echo "N/A"
}
