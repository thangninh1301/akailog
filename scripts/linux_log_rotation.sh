#!/bin/bash

# Include the log function from linux-logmanager.sh
log() {
    local type="$1"
    local msg="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$type] $msg" | tee -a "$log_path"
}

# Function to show usage
usage() {
    echo "Usage: $0 -l <log_path>"
    echo "Options:"
    echo "  -l  Path to the log file"
    exit 1
}

# Check if arguments are passed
if [ "$#" -lt 1 ]; then
    usage
fi

# Parse command-line arguments
while getopts "l:" opt; do
    case $opt in
        l) log_path="$OPTARG" ;;
        *) usage ;;
    esac
done

# Ensure log_path is provided and exists
if [ -z "$log_path" ] || [ ! -f "$log_path" ]; then
    log "ERROR" "Invalid or missing log file path."
    usage
fi

# Log the start of the process
log "INFO" "Started calculating log size based on timestamps for file: $log_path"

# Get the first and last timestamp from the log file
first_timestamp=$(head -n 1 "$log_path" | awk '{print $1, $2}')
last_timestamp=$(tail -n 1 "$log_path" | awk '{print $1, $2}')

if [ -z "$first_timestamp" ] || [ -z "$last_timestamp" ]; then
    log "ERROR" "Could not retrieve timestamps from the log file."
    exit 1
fi

log "INFO" "First timestamp: $first_timestamp"
log "INFO" "Last timestamp: $last_timestamp"

# Calculate log size between first and last timestamp
log_size=$(stat --format="%s" "$log_path")

if [ $? -eq 0 ]; then
    log "INFO" "Total log file size: $log_size bytes"
else
    log "ERROR" "Failed to calculate log size."
    exit 1
fi

# Log the completion of the process
log "INFO" "Completed log size calculation for $log_path"
