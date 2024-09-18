#!/bin/bash

# Function to log the script process
log() {
    local type="$1"
    local msg="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$type] $msg" | tee -a "$log_path"
}

# Function to show usage
usage() {
    echo "Usage: $0 -s <source_log_file> -l <process_log_file>"
    echo "Options:"
    echo "  -s  Path to the source log file (log to calculate)"
    echo "  -l  Path to the log file for this script's output"
    exit 1
}

# Check if arguments are passed
if [ "$#" -lt 1 ]; then
    usage
fi

# Parse command-line arguments
while getopts "s:l:" opt; do
    case $opt in
        s) source_log_path="$OPTARG" ;;
        l) log_path="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure source_log_path is provided and valid
if [ -z "$source_log_path" ] || [ ! -f "$source_log_path" ]; then
    echo "ERROR: Invalid or missing source log file."
    usage
fi

# Ensure log_path is provided, if not, create it
if [ -z "$log_path" ]; then
    echo "ERROR: Missing process log file path."
    usage
fi

# Check if the log file exists, if not, create it
if [ ! -f "$log_path" ]; then
    touch "$log_path"
    if [ $? -ne 0 ]; then
        echo "ERROR: Could not create the process log file at $log_path."
        exit 1
    fi
fi

# Log the start of the process
log "INFO" "Started calculating log size based on timestamps for file: $source_log_path"

# Get the first and last timestamp from the source log file
first_timestamp=$(head -n 1 "$source_log_path" | awk '{print $1, $2}')
last_timestamp=$(tail -n 1 "$source_log_path" | awk '{print $1, $2}')

if [ -z "$first_timestamp" ] || [ -z "$last_timestamp" ]; then
    log "ERROR" "Could not retrieve timestamps from the source log file."
    exit 1
fi

log "INFO" "First timestamp: $first_timestamp"
log "INFO" "Last timestamp: $last_timestamp"

# Calculate log size for the source log file
log_size=$(stat --format="%s" "$source_log_path")

if [ $? -eq 0 ]; then
    log "INFO" "Total source log file size: $log_size bytes"
else
    log "ERROR" "Failed to calculate the size of the source log file."
    exit 1
fi

# Log the completion of the process
log "INFO" "Completed log size calculation for $source_log_path"
