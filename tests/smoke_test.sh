#!/usr/bin/env bash
# Comprehensive Smoke Test Suite for Linux-on-Android
# Designed to run inside Docker or CI environments

set -eo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/linux-on-android.sh"

PASSED=0
FAILED=0

run_test() {
    local test_name="$1"
    shift
    echo -e "\n${CYAN}====================================================${RESET}"
    echo -e "${CYAN}TEST [$(($PASSED + $FAILED + 1))]: ${YELLOW}$test_name${RESET}"
    echo -e "${CYAN}====================================================${RESET}"
    
    if "$@"; then
        echo -e "${GREEN}✓ PASS: $test_name${RESET}"
        PASSED=$(($PASSED + 1))
    else
        echo -e "${RED}✗ FAIL: $test_name${RESET}"
        FAILED=$(($FAILED + 1))
    fi
}

# 1. Setup Mock Environment
echo -e "${CYAN}Setting up test environment and mock utilities...${RESET}"

mkdir -p /usr/local/bin
cat > /usr/local/bin/proot-distro << 'EOF'
#!/bin/bash
case "$1" in
    list)
        echo "debian: installed"
        echo "ubuntu: not installed"
        echo "alpine: not installed"
        ;;
    login)
        shift
        # Consume distro name if present
        if [[ "$1" != "--" && -n "$1" ]]; then shift; fi
        if [[ "$1" == "--" ]]; then shift; fi
        exec "$@"
        ;;
    install)
        echo "[MOCK] Installing $2..."
        sleep 0.1
        echo "[MOCK] $2 installed successfully."
        ;;
    remove)
        echo "[MOCK] Removing $2..."
        sleep 0.1
        echo "[MOCK] $2 removed successfully."
        ;;
    *)
        echo "[MOCK] proot-distro: $*"
        ;;
esac
EOF
chmod +x /usr/local/bin/proot-distro

# Create dummy vncserver, service, and sshd for service tests
cat > /usr/local/bin/vncserver << 'EOF'
#!/bin/bash
echo "[MOCK] vncserver called with: $*"
EOF
chmod +x /usr/local/bin/vncserver

cat > /usr/local/bin/service << 'EOF'
#!/bin/bash
echo "[MOCK] service called with: $*"
EOF
chmod +x /usr/local/bin/service

# Create dummy sample config for debian
mkdir -p "$HOME/.config" "/data/data/com.termux/files/usr/etc/linux-on-android" "/etc/linux-on-android"
cat > "/etc/linux-on-android/debian.conf" << 'EOF'
DISTRO=debian
USERNAME=testuser
GUI=N
RESOLUTION=1920x1080
VNC_PASSWD=1234
EOF

export TERM=xterm-256color
export COLUMNS=80
export LINES=24

# 2. Run Individual Smoke Tests

run_test "CLI Flag: --help" bash -c "bash \"$MAIN_SCRIPT\" --help | grep -q 'Usage:'"

run_test "CLI Flag: --status" bash -c "bash \"$MAIN_SCRIPT\" --status"

run_test "CLI Flag: --doctor" bash -c "printf '\n' | bash \"$MAIN_SCRIPT\" --doctor"

run_test "CLI Flag: --recommend" bash -c "printf '\n' | bash \"$MAIN_SCRIPT\" --recommend"

run_test "CLI Flag: --logs" bash -c "printf '6\n' | bash \"$MAIN_SCRIPT\" --logs"

run_test "CLI Flag: --root" bash -c "printf '7\n' | bash \"$MAIN_SCRIPT\" --root"

run_test "CLI Flag: --auto-install (Direct CLI install)" bash -c "bash \"$MAIN_SCRIPT\" --auto-install alpine"

run_test "CLI Flag: --start-vnc and --stop-vnc" bash -c "bash \"$MAIN_SCRIPT\" --start-vnc && bash \"$MAIN_SCRIPT\" --stop-vnc"

run_test "CLI Flag: --start-ssh and --stop-ssh" bash -c "bash \"$MAIN_SCRIPT\" --start-ssh && bash \"$MAIN_SCRIPT\" --stop-ssh"

run_test "Sub-Menu: Service Management Menu" bash -c "printf '5\n' | bash \"$MAIN_SCRIPT\" --services"

run_test "Sub-Menu: Root Hub Menu" bash -c "printf '7\n' | bash \"$MAIN_SCRIPT\" --root"

run_test "Sub-Menu: Wizard Menu (Exit to main)" bash -c "printf '3\n' | bash \"$MAIN_SCRIPT\" --wizard"

run_test "Wizard: First-Run Wizard (Full execution flow with auto-install)" bash -c "
printf '1\n\n1\n1\n1\n1920x1080\n1234\ny\n' | bash \"$MAIN_SCRIPT\" --wizard
"

run_test "Wizard: Distro Setup Wizard (Cancellation flow)" bash -c "
printf '2\n1\n1\n1\nN\n' | bash \"$MAIN_SCRIPT\" --wizard
"

run_test "Main Menu: Hardware Recommendations" bash -c "printf '5\n\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Service Management sub-entry" bash -c "printf '4\n5\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Package Stacks sub-entry" bash -c "printf '6\n8\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Backup & Restore sub-entry" bash -c "printf '7\n5\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Root Hub sub-entry" bash -c "printf '8\n7\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: View Logs sub-entry" bash -c "printf '9\n6\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: System Diagnostics Doctor sub-entry" bash -c "printf '10\n\n0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Clean Exit with option '13'" bash -c "printf '13\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Clean Exit with '0'" bash -c "printf '0\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Clean Exit with 'q'" bash -c "printf 'q\n' | bash \"$MAIN_SCRIPT\""

run_test "Main Menu: Submenu quick back using 'b'" bash -c "printf '4\nb\nq\n' | bash \"$MAIN_SCRIPT\""

# Summary
echo -e "\n${CYAN}====================================================${RESET}"
echo -e "${CYAN}                  TEST SUMMARY                      ${RESET}"
echo -e "${CYAN}====================================================${RESET}"
echo -e "${GREEN}Total Passed: $PASSED${RESET}"
echo -e "${RED}Total Failed: $FAILED${RESET}"

if [[ $FAILED -eq 0 ]]; then
    echo -e "\n${GREEN}🎉 ALL SMOKE TESTS PASSED SUCCESSFULLY!${RESET}\n"
    exit 0
else
    echo -e "\n${RED}❌ SOME SMOKE TESTS FAILED!${RESET}\n"
    exit 1
fi
