param (
    [string]$LogPath
    [string]$ResultPath
)

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp [$Level] $Message"
    Write-Host $logEntry
    Add-Content -Path $LogPath -Value $logEntry
}


function Show-Usage {
    Write-Host "Usage: .\log_size_by_timestamp.ps1 -LogPath <log_file_path> -ResultPath <result_path>"
    exit 1
}

if (-not $LogPath -or -not (Test-Path $LogPath)) {
    Write-Log "Invalid or missing log file path." -Level "ERROR"
    Show-Usage
}

# Log the start of the process
Write-Log "Started calculating log size based on timestamps for file: $LogPath"

# Read the first and last lines of the log file to extract timestamps
$firstLine = Get-Content -Path $LogPath | Select-Object -First 1
$lastLine = Get-Content -Path $LogPath | Select-Object -Last 1

# Assuming the timestamp is in the first two fields (adjust if needed)
$firstTimestamp = $firstLine -split ' ', 2 | Select-Object -First 2
$lastTimestamp = $lastLine -split ' ', 2 | Select-Object -First 2

if (-not $firstTimestamp -or -not $lastTimestamp) {
    Write-Log "Could not retrieve timestamps from the log file." -Level "ERROR"
    exit 1
}

Write-Log "First timestamp: $firstTimestamp"
Write-Log "Last timestamp: $lastTimestamp"

try {
    $logSize = (Get-Item $LogPath).Length
    Write-Log "Total log file size: $logSize bytes"
} catch {
    Write-Log "Failed to calculate log size." -Level "ERROR"
    exit 1
}

# Log the completion of the process
Write-Log "Completed log size calculation for $LogPath"
