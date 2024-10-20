# Log cleanup job for {{ job_name }}
$leaderPIC = "{{ leader_PIC }}"
$timeToRun = "{{ time_to_run }}"
$host = "{{ ansible_host }}"

# Paths to the log manager scripts
$logManagerScript = "{{ path_job }}\scripts\windows-log-manager.ps1"
$logRotationScript = "{{ path_job }}\scripts\windows-log-rotation.ps1"

# Ensure the log manager scripts exist
if (-Not (Test-Path -Path $logManagerScript)) {
    Write-Error "Error: Log manager script not found at $logManagerScript"
    Exit 1
}

if (-Not (Test-Path -Path $logRotationScript)) {
    Write-Error "Error: Log rotation script not found at $logRotationScript"
    Exit 1
}

# Ensure that result file exists
$resultFile = "result_$(Get-Date -Format 'yyyy-MM-dd_HH-mm-ss').csv"
$resultPath = ".\$resultFile"

# Check if the result path file already exists, if it does, clear its contents, and add header to CSV
"pre_size,cleaned_size,post_size,log_rotation_size,log_rotation_first_time,log_rotation_last_time,pic,job_name,service" | Out-File -FilePath $resultPath -Force

{% for service in services %}
# Service: {{ service.name }}
$servicePath = "{{ service.path }}"

{% if service.retention_rate is defined %}
$retentionRate = {{ service.retention_rate }}
Write-Host "Retention rate: $retentionRate days"
{% endif %}

{% if service.log_extension is defined %}
$logExtension = "{{ service.log_extension }}"
Write-Host "Log Extension: $logExtension"
{% endif %}

{% if service.backup_path is defined %}
$backupEnabled = $true
$backupRetentionRate = {{ service.backup_retention_rate }}
Write-Host "Backup Enabled: Yes"
Write-Host "Backup Retention Rate: $backupRetentionRate days"

{% if service.backup_path is defined %}
$backupPath = "{{ service.backup_path }}"
{% else %}
$backupPath = "$servicePath\backup"
{% endif %}

Write-Host "Backup Path: $backupPath"
{% endif %}

$cleanType = "{{ service.clean_type }}"
Write-Host "Clean Type: $cleanType"

if ($cleanType -eq 'retention') {
    # Call the windows-log-manager script for {{ service.name }}
    & $logManagerScript `
        -ServicePath "$servicePath" `
        -ResultPath $resultPath `
        {% if service.retention_rate is defined %} -RetentionRate $retentionRate {% endif %} `
        {% if service.log_extension is defined %} -LogExtension "$logExtension" {% endif %} `
        {% if service.backup_retention_rate is defined %} -BackupRetentionRate $backupRetentionRate {% endif %} `
        {% if service.backup_path is defined %} -BackupPath "$backupPath" {% endif %}

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Log cleanup (retention) failed for {{ service.name }}"
    } else {
        Write-Host "Log cleanup (retention) succeeded for {{ service.name }}"
    }
} elseif ($cleanType -eq 'rotation') {
    # Call the log-rotation script for {{ service.name }}
    & $logRotationScript `
        -ServicePath "$servicePath" `
        -ResultPath $resultPath

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Error: Log rotation failed for {{ service.name }}"
    } else {
        Write-Host "Log rotation succeeded for {{ service.name }}"
    }
}

# Append information to the result CSV
$csvEntry = ",$leaderPIC,{{ job_name }},{{ service.name }}"
$csvEntry | Out-File -FilePath $resultPath -Append

{% endfor %}

Write-Host "Log cleanup and rotation tasks completed for {{ job_name }} on {{ ansible_host }}"

#------------------------------------------
Write-Host "The $resultFile has been pushed to Nexus"

$NexusUrl = "https://nexus-tcb.techcombank.com.vn/#browse/browse:raw-report-hosted"

Write-Host "Attempting to upload $resultFile to Nexus..."

# Try uploading the file using Invoke-RestMethod
$response = Invoke-RestMethod -Uri "$NexusUrl/$resultFile" -Method Put -InFile $resultPath -ContentType "text/csv"

# Check if the response indicates success (200 or 201)
if ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) {
    Write-Host "File $resultFile successfully uploaded to Nexus."
} else {
    # If the upload fails, log an error and return failure status
    Write-Error "Failed to upload $resultFile. HTTP Status: $($response.StatusCode)"
    Exit 1
}
