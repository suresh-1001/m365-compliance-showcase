$public  = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Public')  -Filter *.ps1 -ErrorAction SilentlyContinue
$private = Get-ChildItem -Path (Join-Path $PSScriptRoot 'Private') -Filter *.ps1 -ErrorAction SilentlyContinue

foreach($f in $private){ . $f.FullName }
foreach($f in $public) { . $f.FullName }

Export-ModuleMember -Function $($public | ForEach-Object { $_.BaseName })
