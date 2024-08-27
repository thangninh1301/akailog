#!/bin/bash


usage() {
  echo "Usage: $0 -d <log_dir> -e <log_extension> -r <retention_day> -o <result_file_path>"
  echo "Example: $0 -d /var/logs -e .log -r 7 -o /tmp/result.txt"
  exit 1
}


# Parse command line arguments
while getopts "d:e:r:o:" opt; do
  case ${opt} in
    d)
      log_dir=${OPTARG}
      ;;
    e)
      log_extension=${OPTARG}
      ;;
    r)
      retention_day=${OPTARG}
      ;;
    o)
      result_file_path=${OPTARG}
      ;;
    *)
      usage
      ;;
  esac
done

if [[ ! -e /tmp/akaijob.log ]]; then
    touch /tmp/akaijob.log
fi

if [[ ! -e /tmp/akaijob-error.log ]]; then
    touch /tmp/akaijob-error.log
fi

log() {
  echo "$(date): $1" >> /tmp/akaijob.log
}

log_error() {
  echo "$(date): ERROR - $1" >> /tmp/akaijob-error.log
}


if [ -z "${log_dir}" ] || [ -z "${log_extension}" ] || [ -z "${retention_day}" ]; then
  usage
fi

if [ ! -d "${log_dir}" ]; then
  log "Error: Log folder ${log_dir} does not exist."
  exit 1
fi


log_pre_size=$(find "${log_dir}" -type f -name "*${log_extension}" -print0 | xargs -0 du -sb | awk '{sum+=$1} END {print sum}')


log_cleaned_size=$(find "${log_dir}" -type f -name "*${log_extension}" -mtime +${retention_day} -print0 | xargs -0 du -sb | awk '{sum+=$1} END {print sum}')


list_files_to_remove=$(find "${log_dir}" -type f -name "*${log_extension}" -mtime +"${retention_day}") ;

for file in ${list_files_to_remove}; do
    if [ -f "$file" ]; then
        rm "$file"
        log "Deleted: $file"
    else
        log_error "File not found: $file"
    fi
done

log_post_size=$(find "${log_dir}" -type f -name "*${log_extension}" -print0 | xargs -0 du -sb | awk '{sum+=$1} END {print sum}')


# Calculate post-cleaning size
post_size=$(du -sh "${log_dir}" | cut -f1)

echo "$log_pre_size, $log_cleaned_size, $log_post_size" >> "$result_file_path"

