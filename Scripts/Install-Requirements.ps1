Param(
    [switch]$Force
)

Write-Host "Ensuring PowerShell 7+ modules are present..."

$modules = @(
    @{ Name = "Microsoft.Graph"; Repository = "PSGallery" },
    @{ Name = "ExchangeOnlineManagement"; Repository = "PSGallery" }
)

foreach ($m in $modules) {
    $installed = Get-Module -ListAvailable -Name $m.Name | Select-Object -First 1
    if (-not $installed -or $Force) {
        Write-Host "Installing $($m.Name)..."
        Install-Module -Name $m.Name -Repository $m.Repository -Scope CurrentUser -Force -AllowClobber
    } else {
        Write-Host "$($m.Name) already installed."
    }
}

Write-Host "Done."
