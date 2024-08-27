param (
    [string]$logDir,
    [string]$logExtension,
    [int]$retentionDay,
    [string]$resultFilePath
)

function Usage {
    Write-Host "Usage: script.ps1 -logDir <log_dir> -logExtension <log_extension> -retentionDay <retention_day> -resultFilePath <result_file_path>"
    Write-Host "Example: script.ps1 -logDir C:\Logs -logExtension .log -retentionDay 7 -resultFilePath C:\temp\result.txt"
    exit 1
}

# Create log files if they don't exist
$logFile = "C:\temp\akaijob.log"
$errorLogFile = "C:\temp\akaijob-error.log"

if (-not (Test-Path $logFile)) {
    New-Item -Path $logFile -ItemType File -Force
}

if (-not (Test-Path $errorLogFile)) {
    New-Item -Path $errorLogFile -ItemType File -Force
}

function Log {
    param (
        [string]$message
    )
    Add-Content -Path $logFile -Value "$(Get-Date): $message"
}

function LogError {
    param (
        [string]$message
    )
    Add-Content -Path $errorLogFile -Value "$(Get-Date): ERROR - $message"
}

# Check for required parameters
if (-not $logDir -or -not $logExtension -or -not $retentionDay -or -not $resultFilePath) {
    Usage
}

# Check if log directory exists
if (-not (Test-Path $logDir)) {
    Log "Error: Log directory $logDir does not exist."
    exit 1
}

# Calculate pre-cleaning size
$logPreSize = Get-ChildItem -Path $logDir -Recurse -Filter "*$logExtension" | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum

# Calculate size of logs to be cleaned
$logCleanedSize = Get-ChildItem -Path $logDir -Recurse -Filter "*$logExtension" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDay) } | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum

# Find and delete old log files
$listFilesToRemove = Get-ChildItem -Path $logDir -Recurse -Filter "*$logExtension" | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$retentionDay) }

foreach ($file in $listFilesToRemove) {
    if (Test-Path $file.FullName) {
        Remove-Item $file.FullName -Force
        Log "Deleted: $($file.FullName)"
    } else {
        LogError "File not found: $($file.FullName)"
    }
}

# Calculate post-cleaning size
$logPostSize = Get-ChildItem -Path $logDir -Recurse -Filter "*$logExtension" | Measure-Object -Property Length -Sum | Select-Object -ExpandProperty Sum

# Output the results to the specified file
"$logPreSize, $logCleanedSize" | Out-File -FilePath $resultFilePath -Append

# Log completion
Log "Log cleanup complete. Results saved to $resultFilePath."
