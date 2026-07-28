$repo = "YaVoznyuk/PCDeploy"

Write-Host "Getting latest release..."

$release = Invoke-RestMethod "https://api.github.com/repos/$repo/releases/latest"

$asset = $release.assets | Where-Object { $_.name -eq "PCDeploy.zip" }

if (-not $asset) {
    Write-Host "PCDeploy.zip not found in latest release."
    exit
}

$zip = Join-Path $env:TEMP "PCDeploy.zip"
$folder = Join-Path $env:TEMP "PCDeploy"

if (Test-Path $folder) {
    Remove-Item $folder -Recurse -Force
}

Invoke-WebRequest $asset.browser_download_url -OutFile $zip

Expand-Archive $zip $folder -Force

powershell -ExecutionPolicy Bypass -File (Join-Path $folder "Install-PC.ps1")
