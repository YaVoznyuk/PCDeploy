# ================================
# PCDeploy v2
# ================================

$InstallerRoot = Join-Path $PSScriptRoot "Installers"

# Перевірка адміністратора
$CurrentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($CurrentUser)

if (-not $Principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
    Write-Host "Run PowerShell as Administrator." -ForegroundColor Red
    Pause
    exit
}

# Список програм
$AppsFile = Join-Path $PSScriptRoot "apps.json"

if(!(Test-Path $AppsFile))
{
    Write-Host "apps.json not found." -ForegroundColor Red
    Pause
    exit
}

$Apps = Get-Content $AppsFile | ConvertFrom-Json

function Test-AppInstalled
{
    param([string]$Name)

    $paths=@(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach($path in $paths)
    {
        if(Get-ItemProperty $path -ErrorAction SilentlyContinue |
            Where-Object {$_.DisplayName -like "*$Name*"})
        {
            return $true
        }
    }

    return $false
}

function Find-Installer
{
    param($Folder)

    $Path = Join-Path $InstallerRoot $Folder

    if(!(Test-Path $Path))
    {
        return $null
    }

    $File = Get-ChildItem $Path -File |
        Where-Object {
            $_.Extension -in ".exe",".msi"
        } |
        Select-Object -First 1

    return $File
}

function Install-App
{
    param($App)

    Write-Host ""
    Write-Host "-----------------------------------"
    Write-Host "Checking $($App.Name)..."

    if(Test-AppInstalled $App.Check)
    {
        Write-Host "Already installed." -ForegroundColor Green
        return
    }

    $Installer = Find-Installer $App.Folder

    if(!$Installer)
    {
        Write-Host "Installer not found." -ForegroundColor Red
        return
    }

    Write-Host "Installing..."

    if($Installer.Extension -eq ".msi")
    {
        Start-Process msiexec.exe `
            -ArgumentList "/i `"$($Installer.FullName)`" /qn /norestart" `
            -Wait
    }
    else
    {
        Start-Process `
            -FilePath $Installer.FullName `
            -ArgumentList $App.Args `
            -Wait
    }

    if(Test-AppInstalled $App.Check)
    {
        Write-Host "Installed successfully." -ForegroundColor Green
    }
    else
    {
        Write-Host "Installation finished. Verification failed." -ForegroundColor Yellow
    }
}

Clear-Host

Write-Host "======================================="
Write-Host " PCDeploy"
Write-Host "======================================="

foreach($App in $Apps)
{
    Install-App $App
}

Write-Host ""
Write-Host "Done."

Pause
