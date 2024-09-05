#!/bin/bash

# Functions

usage() {
    echo "Usage: $0 -s <source_path> -k <log_history> -b <backup_path> -h <backup_retention> -w <work_dir> -z <zip_name> -l <log_path> -r <log_retention> -S <smtp_server> -p <smtp_port> -u <smtp_user> -P <smtp_pwd> -t <mail_to> -f <mail_from> -j <mail_subject> [-c] [-z] [-n] [-H] -e <log_extension>"
    echo "Options:"
    echo "  -s  Path to logs"
    echo "  -k  Number of days to keep logs"
    echo "  -b  Path to backup"
    echo "  -h  Number of days to keep backups"
    echo "  -w  Working directory"
    echo "  -z  Zip file name"
    echo "  -l  Log file path"
    echo "  -r  Days to keep logs produced by the utility"
    echo "  -e  Log file extension to calculate sizes"
    echo "  -c  Compress logs"
    echo "  -H  Show help"
}

# Default values
log_history=0
backup_retention=0
compress=false
log_extension=""

# Parse command-line arguments
while getopts "s:k:b:h:w:z:l:r:e:S:p:u:P:t:f:j:cznH" opt; do
    case $opt in
        s) source_path="$OPTARG" ;;
        k) log_history="$OPTARG" ;;
        b) backup_path="$OPTARG" ;;
        h) backup_retention="$OPTARG" ;;
        w) work_dir="$OPTARG" ;;
        z) zip_name="$OPTARG" ;;
        l) log_path="$OPTARG" ;;
        r) log_retention="$OPTARG" ;;
        e) log_extension="$OPTARG" ;;  # Log extension to filter files
        H) usage; exit 0 ;;
        *) usage; exit 1 ;;
    esac
done

log() {
    local type="$1"
    local msg="$2"
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$timestamp [$type] $msg" | tee -a "$log_path"
}

# Function to calculate folder size
calculate_size() {
    local folder="$1"
    local extension="$2"
    find "$folder" -type f -name "*${extension}" -exec du -ch {} + | grep total$ | cut -f1
}

# Compress logs
compress_logs() {
    log "INFO" "Compressing using gzip"
    tar -czf "$work_dir/$zip_name-$(date +'%Y-%m-%d_%H-%M-%S').tar.gz" -C "$work_dir" "$zip_name"
}

if [ -z "$source_path" ]; then
    log "ERROR" "You must specify -s <source_path>."
    exit 1
fi

if [ ! -d "$log_path" ]; then
    mkdir -p "$log_path"
fi

log "INFO" "Process started"

# Calculate Pre-cleaning size
pre_size=$(calculate_size "$source_path" "$log_extension")
log "INFO" "Pre-cleaning size of logs with extension $log_extension: $pre_size"

# Calculate size of files to be cleaned
cleaned_size=$(find "$source_path" -type f -name "*${log_extension}" -mtime +"$log_history" -exec du -ch {} + | grep total$ | cut -f1)
log "INFO" "Total size of files to be cleaned: $cleaned_size"

# Remove old logs
find "$source_path" -type f -name "*${log_extension}" -mtime +"$log_history" -exec rm -f {} \;

# Backup logs
if [ -n "$backup_path" ]; then
    cp -r "$source_path" "$work_dir/$zip_name"
    if [ "$compress" = true ]; then
        compress_logs
    fi
    mv "$work_dir/$zip_name"* "$backup_path"
    find "$backup_path" -type f -mtime +"$backup_retention" -exec rm -f {} \;
fi

# Calculate Post-cleaning size
post_size=$(calculate_size "$source_path" "$log_extension")
log "INFO" "Post-cleaning size of logs with extension $log_extension: $post_size"

# Rotate logs
if [ -n "$log_retention" ]; then
    log "INFO" "Cleaning all logs older than $log_retention days"
    find "$log_path" -type f -mtime +"$log_retention" -exec rm -f {} \;
fi

log "INFO" "Process completed"
