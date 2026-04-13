# Authored by Sam Lynas using a brutally modified version of the original @ https://powershellisfun.com/2024/01/19/using-the-powershell-pswindowsupdate-module
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
# old version of line below:  if (Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue) { Write-Host 'NuGet provider already installed' } 
############################ another old version
#else { Write-Host 'Installing NuGet provider...'; Install-PackageProvider -Name 'NuGet' -Force }
#if (Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue) { 
#    Write-Host 'NuGet provider already installed' 
#} else { 
#    Write-Host 'Installing NuGet provider...'; 
#    Find-PackageProvider -Name 'NuGet' -ForceBootstrap -IncludeDependencies -Force | Out-Null
#}
# install the new package manager
# Set TLS for download
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# Download if missing (to temp SYSTEM-writable path)
$nugetDllUrl = 'https://cdn.oneget.org/providers/Microsoft.PackageManagement.NuGetProvider-2.8.5.208.dll'
$nugetPath = 'C:\Program Files\PackageManagement\ProviderAssemblies\nuget\2.8.5.208\Microsoft.PackageManagement.NuGetProvider.dll'
$nugetFolder = Split-Path $nugetPath -Parent

if (-not (Test-Path $nugetPath)) {
    if (-not (Test-Path $nugetFolder)) { New-Item -Path $nugetFolder -ItemType Directory -Force | Out-Null }
    Invoke-WebRequest -Uri $nugetDllUrl -OutFile $nugetPath -UseBasicParsing
    Write-Host 'NuGet DLL manually installed'
}

# Now register/import (no prompt)
Import-PackageProvider -Name NuGet -RequiredVersion 2.8.5.208 -Force | Out-Null
Write-Host 'NuGet provider ready'

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

if (Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue) {
    Write-Host 'NuGet provider already installed'
} else {
    Write-Host 'Installing NuGet provider...'
    Install-PackageProvider -Name 'NuGet' -MinimumVersion '2.8.5.201' -ForceBootstrap -Force -Confirm:$false -Scope CurrentUser | Out-Null
    if (Get-PackageProvider -Name 'NuGet' -ErrorAction SilentlyContinue) {
        Import-PackageProvider -Name 'NuGet' -Force | Out-Null
        Write-Host 'NuGet provider installed successfully'
    } else {
        Write-Error 'NuGet installation failed'
    }
}

# Attempt to Install+Import PSWindowsUpdate with CurrentUser scope, if fails use AllUsers
try {
    Install-Module PSWindowsUpdate -Scope CurrentUser -Force -ErrorAction Stop
    Write-Host "PSWindowsUpdate installed to CurrentUser path (SYSTEM context)" -ForegroundColor Green
} catch {
    Write-Warning "CurrentUser failed in SYSTEM session: $($_.Exception.Message)"
    Install-Module PSWindowsUpdate -Scope AllUsers -Force
    Write-Host "PSWindowsUpdate installed to AllUsers (Program Files)" -ForegroundColor Yellow
}

Import-Module PSWindowsUpdate -Force
# the command that I previously used is REMmed out below:
# if (Get-Module -ListAvailable -Name 'PSWindowsUpdate') { Write-Host 'PSWindowsUpdate already installed'; Import-Module PSWindowsUpdate } else { Write-Host 'Installing PSWindowsUpdate...'; Install-Module PSWindowsUpdate -Scope CurrentUser -Force; Import-Module PSWindowsUpdate }

# if import fails, unREM the line below:
# Install-Module PSWindowsUpdate -Scope AllUsers -Force

Get-WindowsUpdate
Install-WindowsUpdate -AcceptAll -IgnoreReboot
# for a specific update use: Install-WindowsUpdate (or Uninstall-WindowsUpdate) -KBArticleID KB#########
##### if it fails, un-REM the next line
# Register-PSRepository -Default
# Un-REM line below to determine if PS Repository is working
# Get-PSRepository
 if (Get-WURebootStatus) { Write-Host "REBOOT REQUIRED for updates to complete!" -ForegroundColor Red } else { Write-Host "No reboot needed." -ForegroundColor Green } 
 
# choco
choco upgrade all
