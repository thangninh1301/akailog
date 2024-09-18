param (
    [string]$sourceLogPath,
    [string]$logPath
)

# Function to log messages to the process log file
function Log-Message {
    param (
        [string]$type,
        [string]$message
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$type] $message"
    Add-Content -Path $logPath -Value $logEntry
}

# Function to show usage
function Show-Usage {
    Write-Host "Usage: .\log_manager.ps1 -sourceLogPath <source_log_file> -logPath <process_log_file>"
    Exit 1
}

# Check if arguments are provided
if (-not $sourceLogPath -or -not $logPath) {
    Show-Usage
}

# Check if the source log file exists
if (-not (Test-Path $sourceLogPath)) {
    Write-Host "ERROR: Invalid or missing source log file."
    Show-Usage
}

# Check if the process log file exists, create it if not
if (-not (Test-Path $logPath)) {
    New-Item -Path $logPath -ItemType File -Force
}

# Log the start of the process
Log-Message -type "INFO" -message "Started calculating log size based on timestamps for file: $sourceLogPath"

# Get the first and last timestamp from the source log file
$firstLine = Get-Content $sourceLogPath -TotalCount 1
$lastLine = Get-Content $sourceLogPath | Select-Object -Last 1

# Extract timestamps from the log file (assuming the first two columns are the timestamp)
$firstTimestamp = $firstLine -match '^(\S+\s+\S+)' | Out-Null; $matches[0]
$lastTimestamp = $lastLine -match '^(\S+\s+\S+)' | Out-Null; $matches[0]

if (-not $firstTimestamp -or -not $lastTimestamp) {
    Log-Message -type "ERROR" -message "Could not retrieve timestamps from the source log file."
    Exit 1
}

Log-Message -type "INFO" -message "First timestamp: $firstTimestamp"
Log-Message -type "INFO" -message "Last timestamp: $lastTimestamp"

# Get the size of the source log file
$logSize = (Get-Item $sourceLogPath).length

if ($logSize -ne $null) {
    Log-Message -type "INFO" -message "Total source log file size: $logSize bytes"
} else {
    Log-Message -type "ERROR" -message "Failed to calculate log size."
    Exit 1
}

# Log the completion of the process
Log-Message -type "INFO" -message "Completed log size calculation for $sourceLogPath"
