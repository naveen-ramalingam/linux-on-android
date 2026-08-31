#!/bin/bash
# User and Privilege Management

setup_user() {
    local distro="$1"
    local username="$2"
    local password="$3"

    echo "Creating user $username..."
    proot-distro login "$distro" -- useradd -m -s /bin/bash "$username"
    echo "$username:$password" | proot-distro login "$distro" -- chpasswd
    
    # Configure sudo
    proot-distro login "$distro" -- bash -c "echo '$username ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/$username && chmod 440 /etc/sudoers.d/$username"
}
