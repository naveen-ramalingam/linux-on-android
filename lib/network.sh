#!/bin/bash
# Network detection and info

get_local_ip() {
    ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1 || hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
}

get_active_interfaces() {
    ip link show 2>/dev/null | awk -F: '$0 !~ "lo|vir|wl" {print $2}' | tr -d ' ' || echo "wlan0"
}
