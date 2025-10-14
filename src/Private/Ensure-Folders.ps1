function Ensure-Folders {
    param([Parameter(Mandatory)][string]$Path)
    if(-not (Test-Path $Path)){
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}
