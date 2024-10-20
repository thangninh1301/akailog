calculate_size() {
    local folder="$1"
    local extension="$2"
    total_size=$(find "$folder" -type f -name "*${extension}" -exec ls -l {} + | awk '{total += $5} END {print total}')
    echo "scale=2; $total_size / 1024" | bc
}
