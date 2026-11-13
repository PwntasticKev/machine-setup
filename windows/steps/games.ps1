# Riot games and the Jagex Launcher.

# Installed one after another in their own window, so the big downloads run
# while the rest of setup continues. TFT is played inside League.
$script:RiotPackages = @('RiotGames.LeagueOfLegends.NA', 'RiotGames.Valorant.NA')
$script:RiotWindowTitle = 'Riot downloads'
$script:JagexInstallerUrl = 'https://cdn.jagex.com/Jagex%20Launcher%20Installer.exe'

function Get-RiotDownloadCommand {
    $flags = $script:WingetFlags -join ' '
    $lines = @("`$Host.UI.RawUI.WindowTitle = '$($script:RiotWindowTitle)'")
    foreach ($id in $script:RiotPackages) {
        $lines += "winget list --id $id --exact --accept-source-agreements --disable-interactivity *> `$null"
        $lines += "if (`$LASTEXITCODE -eq 0) { Write-Host '$id already installed.' } else { Write-Host 'Installing $id (downloads the full game)' -ForegroundColor Cyan; winget install --id $id --source winget $flags }"
    }
    $lines += "Write-Host 'Riot downloads finished. Reboot once so the Valorant anti-cheat (Vanguard) can start.' -ForegroundColor Green"
    $lines += "Read-Host 'Press Enter to close'"
    return $lines -join '; '
}

function Start-RiotDownloads {
    $command = Get-RiotDownloadCommand
    if ($script:DryRun) { Write-Info "[dry-run] new window: $command"; return $true }

    Start-Process -FilePath 'powershell.exe' -WindowStyle Minimized -ArgumentList @(
        '-NoProfile', '-ExecutionPolicy', 'Bypass', '-Command', $command
    )
    Write-Info "League of Legends and Valorant are downloading in the minimized '$($script:RiotWindowTitle)' window."
    Add-Todo "Wait for the '$($script:RiotWindowTitle)' window to finish, then reboot (Valorant needs it)"
    Add-Todo 'Log into the Riot Client'
    return $true
}

function Test-JagexInstalled {
    $keys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    $found = Get-ItemProperty -Path $keys -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName -like 'Jagex Launcher*' }
    return [bool]$found
}

function Install-JagexLauncher {
    if (Test-JagexInstalled) { Write-Info 'Jagex Launcher already installed.'; return $true }
    if ($script:DryRun) { Write-Info "[dry-run] download and run $($script:JagexInstallerUrl)"; return $true }

    $exe = Invoke-Download -Url $script:JagexInstallerUrl -FileName 'JagexLauncherInstaller.exe'
    Write-Info 'Running the Jagex Launcher installer (click through it if it asks).'
    if (-not (Invoke-Installer -Path $exe -Name 'Jagex Launcher')) { return $false }
    Add-Todo 'Log into the Jagex Launcher and install Old School RuneScape'
    return $true
}
