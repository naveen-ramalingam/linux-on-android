#!/bin/bash
# System diagnostics and problem resolution

run_diagnostics() {
    draw_header "System Diagnostics"
    draw_card "Running comprehensive checks..." \
        "" \
        "${CYAN}1)${RESET} proot-distro: $(command -v proot-distro || echo '${RED}Not Found${RESET}')" \
        "${CYAN}2)${RESET} Root Access: $(get_root_type 2>/dev/null || echo 'Not Rooted')" \
        "${CYAN}3)${RESET} Storage: $(get_storage_free)" \
        "${CYAN}4)${RESET} Termux: $IS_TERMUX" \
        "${CYAN}5)${RESET} CPU: $(get_cpu_arch)" \
        "${CYAN}6)${RESET} RAM: $(get_ram_free 2>/dev/null || echo 'N/A')"
    echo -e "\n${GREEN}✓ Diagnostics complete${RESET}"
    echo ""
    read -rp "${YELLOW}Press Enter to continue...${RESET}" _
}
