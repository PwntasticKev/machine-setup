# One-line Windows bootstrap (run in PowerShell):
#   irm https://raw.githubusercontent.com/PwntasticKev/machine-setup/main/install.ps1 | iex
# Downloads this repo (no git needed on a fresh PC) and runs windows\setup.ps1.
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$repo = 'PwntasticKev/machine-setup'
$branch = if ($env:MACHINE_SETUP_BRANCH) { $env:MACHINE_SETUP_BRANCH } else { 'main' }
$dest = if ($env:MACHINE_SETUP_DIR) { $env:MACHINE_SETUP_DIR } else { Join-Path $env:USERPROFILE '.machine-setup' }

$work = Join-Path $env:TEMP ("machine-setup-" + [guid]::NewGuid())
$zip = "$work.zip"

Write-Host "==> Downloading $repo ($branch)"
Invoke-WebRequest -Uri "https://github.com/$repo/archive/refs/heads/$branch.zip" -OutFile $zip -UseBasicParsing
Expand-Archive -Path $zip -DestinationPath $work -Force

if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
Move-Item (Join-Path $work "machine-setup-$branch") $dest
Remove-Item $zip, $work -Recurse -Force -ErrorAction SilentlyContinue

& powershell.exe -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dest 'windows\setup.ps1')
