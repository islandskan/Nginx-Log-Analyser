#!/bin/bash
# Tool to analyze logs from a sample nginx log file
# 

set -euo pipefail

FILE_PATTERN='^([a-zA-Z0-9._/-]+)\.(log|txt)$'
 # shellcheck disable=SC2155
readonly SCRIPT_NAME=$(basename "$0")
LOG_FILE="${1:-}"

function get_ip_addresses() {
    echo -e "\n--- Top 5 IP Addresses with most requests ---"
    awk '{print $1}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk 'NR <= 5 {printf "%-25s %s requests\n", $2, $1}'
}

function get_requested_paths() {
    echo -e "\n--- Top 5 Resquested Paths ---"
    awk '{print $7}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk 'NR <= 5 {printf "%-25s %s requests\n", $2, $1}'
}

get_response_status_codes() {
    echo -e "\n--- Top 5 Response Status Codes ---"
    awk '$9 ~ /^[0-9]{3}$/ {print $9}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk 'NR <= 5 {printf "%-25s %s requests\n", $2, $1}'
}

get_user_agents() {
    echo -e "\n--- Top 5 User Agents ---" 
    awk -F'\"' '{print $6}' "$LOG_FILE" | sort | uniq -c | sort -nr | awk 'NR <= 5 {
        count = $1;
        $1 = "";
        sub(/^[ \t]+/, "");
        printf "%-75.70s %s requests\n", $0, count
    }'
}

function usage() {
    local exit_code="${1:-0}"
    echo "Usage: $SCRIPT_NAME <log-file>"
    echo ""
    echo "Arguments:"
    echo "log-file          The name/path of the log file to analyze."
    echo ""
    exit "$exit_code"
}

function validate_file() {
    if [[ -z "$LOG_FILE" ]]; then
        echo "[ERROR] Missing required argument: log-file"
        usage 1
    fi
    if [[ ! $LOG_FILE =~ $FILE_PATTERN ]]; then
        echo "[ERROR] Invalid file format. Must be .txt or .log and must contain valid characters (a-z, A-Z, 0-9, /, ., -, or _)"
        exit 1
    fi  
    if [[ ! -f "$LOG_FILE" ]]; then
        echo "[ERROR] File $LOG_FILE not found"
        exit 1
    fi
}

function main() {
    validate_file
    get_ip_addresses
    get_requested_paths
    get_response_status_codes
    get_user_agents
}

main "$@"
