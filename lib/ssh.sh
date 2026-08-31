#!/bin/bash
# SSH Server Management

start_ssh() {
    local distro="$1"
    echo "Starting SSH server..."
    proot-distro login "$distro" -- service ssh start || proot-distro login "$distro" -- /etc/init.d/ssh start
}

stop_ssh() {
    local distro="$1"
    echo "Stopping SSH server..."
    proot-distro login "$distro" -- service ssh stop || proot-distro login "$distro" -- /etc/init.d/ssh stop
}

is_ssh_running() {
    local distro="$1"
    proot-distro login "$distro" -- pgrep sshd &>/dev/null
}
