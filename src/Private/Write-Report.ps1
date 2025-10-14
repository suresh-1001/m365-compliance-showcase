function Write-Report {
    param(
        [Parameter(Mandatory)]$Object,
        [Parameter(Mandatory)][string]$File
    )
    $dir = Split-Path -Parent $File
    if(-not (Test-Path $dir)){
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $Object | ConvertTo-Json -Depth 8 | Out-File -FilePath $File -Encoding UTF8 -Force
    Write-Host "Wrote $File"
}
