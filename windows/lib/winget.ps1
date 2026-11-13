# winget helpers. Dot-sourced, not executed.

$script:WingetFlags = @(
    '--exact', '--silent', '--disable-interactivity',
    '--accept-package-agreements', '--accept-source-agreements'
)
# Exit codes that mean "installed, reboot later".
$script:RebootExitCodes = @(3010, 1641)
# Another installer (often the Riot download window) is busy: wait and retry.
$script:InstallerBusyExitCode = 1618
$script:BusyRetries = 3
$script:BusyRetrySeconds = 30

function Test-WingetInstalled([string]$Id) {
    # Native stderr must not become a terminating error under 'Stop'.
    $ErrorActionPreference = 'Continue'
    & winget list --id $Id --exact --accept-source-agreements --disable-interactivity *> $null
    return $LASTEXITCODE -eq 0
}

function Invoke-WingetInstall([string]$Id, [string]$Source) {
    $ErrorActionPreference = 'Continue'
    # Out-Host keeps winget's output out of this function's return value.
    & winget install --id $Id --source $Source @script:WingetFlags | Out-Host
    return $LASTEXITCODE
}

function Install-WingetPackage([string]$Id, [string]$Source = 'winget') {
    if ($script:DryRun) { Write-Info "[dry-run] winget install --id $Id --source $Source"; return $true }
    if (Test-WingetInstalled $Id) { Write-Info "$Id already installed."; return $true }

    Write-Info "Installing $Id"
    $code = Invoke-WingetInstall $Id $Source
    for ($try = 1; $code -eq $script:InstallerBusyExitCode -and $try -le $script:BusyRetries; $try++) {
        Write-Info "Another installer is running; retrying $Id in $($script:BusyRetrySeconds)s ($try/$($script:BusyRetries))"
        Start-Sleep -Seconds $script:BusyRetrySeconds
        $code = Invoke-WingetInstall $Id $Source
    }

    if ($code -eq 0) { return $true }
    if ($script:RebootExitCodes -contains $code) {
        Add-Todo "Reboot to finish installing $Id"
        return $true
    }
    Write-Warn "$Id failed with winget exit code $code"
    return $false
}

# Installs every package in a packages file; returns $false if any failed.
function Install-WingetList([string]$Path) {
    $allOk = $true
    foreach ($line in Get-ConfigLines $Path) {
        $parts = $line -split '\s+'
        $source = if ($parts.Count -gt 1) { $parts[1] } else { 'winget' }
        if (-not (Install-WingetPackage -Id $parts[0] -Source $source)) { $allOk = $false }
    }
    return $allOk
}
