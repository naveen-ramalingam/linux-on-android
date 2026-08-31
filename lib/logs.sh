#!/bin/bash
# Unified logging framework for Linux-on-Android
# Provides structured logging with levels, rotation, and interactive viewer

# Log configuration
LOG_DIR="${HOME}/.linux-on-android/logs"
LOG_FILE="${LOG_DIR}/main.log"
LOG_MAX_SIZE=10485760  # 10MB
LOG_MAX_FILES=5

# Log levels
LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_WARN=2
LOG_LEVEL_ERROR=3
LOG_LEVEL_FATAL=4

CURRENT_LOG_LEVEL=${LOG_LEVEL_INFO:-$LOG_LEVEL_INFO}

# Initialize logging
init_logging() {
    mkdir -p "$LOG_DIR"
    
    # Rotate logs if needed
    if [[ -f "$LOG_FILE" ]]; then
        local size=$(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE" 2>/dev/null)
        if [[ "$size" -gt "$LOG_MAX_SIZE" ]]; then
            rotate_logs
        fi
    fi
}

# Rotate log files
rotate_logs() {
    echo "Rotating logs..."
    
    # Delete oldest log
    if [[ -f "${LOG_FILE}.${LOG_MAX_FILES}" ]]; then
        rm -f "${LOG_FILE}.${LOG_MAX_FILES}"
    fi
    
    # Rotate existing logs
    for i in $(seq $((LOG_MAX_FILES - 1)) -1 1); do
        if [[ -f "${LOG_FILE}.${i}" ]]; then
            mv "${LOG_FILE}.${i}" "${LOG_FILE}.$((i + 1))"
        fi
    done
    
    # Rotate current log
    if [[ -f "$LOG_FILE" ]]; then
        mv "$LOG_FILE" "${LOG_FILE}.1"
    fi
    
    # Create new log file
    touch "$LOG_FILE"
}

# Format timestamp
get_timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

# Write log entry
write_log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(get_timestamp)
    
    local level_name
    case "$level" in
        $LOG_LEVEL_DEBUG) level_name="DEBUG" ;;
        $LOG_LEVEL_INFO)  level_name="INFO"  ;;
        $LOG_LEVEL_WARN)  level_name="WARN"  ;;
        $LOG_LEVEL_ERROR) level_name="ERROR" ;;
        $LOG_LEVEL_FATAL) level_name="FATAL" ;;
        *) level_name="INFO" ;;
    esac
    
    echo "[${timestamp}] [${level_name}] ${message}" >> "$LOG_FILE"
}

# Convenience functions
log_debug() { write_log $LOG_LEVEL_DEBUG "$@"; }
log_info()  { write_log $LOG_LEVEL_INFO "$@"; }
log_warn()  { write_log $LOG_LEVEL_WARN "$@"; }
log_error() { write_log $LOG_LEVEL_ERROR "$@"; }
log_fatal() { write_log $LOG_LEVEL_FATAL "$@"; }

# View logs interactively
view_logs() {
    local filter=""
    local lines=50
    
    while true; do
        echo ""
        echo "=== Log Viewer ==="
        echo ""
        echo "1) View recent logs (last $lines lines)"
        echo "2) Filter by level"
        echo "3) Search logs"
        echo "4) Export logs"
        echo "5) Clear logs"
        echo "6) Back"
        echo ""
        read -rp "Select option: " choice
        
        case "$choice" in
            1)
                echo ""
                echo "--- Last $lines lines ---"
                tail -n "$lines" "$LOG_FILE" 2>/dev/null || echo "No logs available"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            2)
                echo ""
                echo "Filter by: (DEBUG/INFO/WARN/ERROR/FATAL)"
                read -rp "Enter level: " level
                echo ""
                grep "\[${level}\]" "$LOG_FILE" 2>/dev/null | tail -n "$lines" || echo "No matching logs"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            3)
                read -rp "Enter search term: " term
                echo ""
                grep -i "$term" "$LOG_FILE" 2>/dev/null | tail -n "$lines" || echo "No matching logs"
                echo ""
                read -rp "Press Enter to continue..."
                ;;
            4)
                local export_file="${HOME}/linux-on-android-logs-$(date +%Y%m%d-%H%M%S).txt"
                cp "$LOG_FILE" "$export_file" 2>/dev/null
                echo "${GREEN}✓ Logs exported to: $export_file${RESET}"
                ;;
            5)
                read -rp "Clear all logs? (y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    > "$LOG_FILE"
                    echo "${GREEN}✓ Logs cleared${RESET}"
                fi
                ;;
            6)
                break
                ;;
            *)
                echo "${RED}Invalid option${RESET}"
                ;;
        esac
    done
}

# Get log statistics
get_log_stats() {
    echo ""
    echo "=== Log Statistics ==="
    echo ""
    
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "No logs available"
        return
    fi
    
    local total_lines=$(wc -l < "$LOG_FILE")
    local error_count=$(grep -c "\[ERROR\]" "$LOG_FILE" 2>/dev/null || echo 0)
    local warn_count=$(grep -c "\[WARN\]" "$LOG_FILE" 2>/dev/null || echo 0)
    local info_count=$(grep -c "\[INFO\]" "$LOG_FILE" 2>/dev/null || echo 0)
    
    echo "Total entries: $total_lines"
    echo "Errors: $error_count"
    echo "Warnings: $warn_count"
    echo "Info: $info_count"
    echo ""
    
    if [[ "$error_count" -gt 0 ]]; then
        echo "${YELLOW}Recent errors:${RESET}"
        grep "\[ERROR\]" "$LOG_FILE" | tail -5
    fi
}

# Initialize logging on source
init_logging
