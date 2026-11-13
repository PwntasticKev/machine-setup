# Windows apps from packages.txt, Dia, Claude skills and the default browser.

$script:DiaInstallerUrl = 'https://releases.diabrowser.com/windows/release/DiaInstaller.exe'

function Install-Apps {
    $ok = Install-WingetList (Join-Path $script:WindowsDir 'packages.txt')
    Update-SessionPath
    return $ok
}

function Test-DiaInstalled {
    $paths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\Dia'),
        (Join-Path $env:LOCALAPPDATA 'Dia'),
        (Join-Path $env:ProgramFiles 'Dia')
    )
    return [bool]($paths | Where-Object { Test-Path $_ })
}

function Install-Dia {
    if (Test-DiaInstalled) { Write-Info 'Dia already installed.'; return $true }
    if ($script:DryRun) { Write-Info "[dry-run] download and run $($script:DiaInstallerUrl)"; return $true }

    $exe = Invoke-Download -Url $script:DiaInstallerUrl -FileName 'DiaInstaller.exe'
    Write-Info 'Running the Dia installer (click through it if it asks).'
    return (Invoke-Installer -Path $exe -Name 'Dia')
}

function Install-Skills {
    Update-SessionPath
    if (-not $script:DryRun -and -not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Write-Warn 'npx not found; Node did not install.'
        return $false
    }
    $allOk = $true
    foreach ($repo in Get-ConfigLines (Join-Path $script:ConfigDir 'skills.txt')) {
        Write-Info "Installing skills from $repo"
        if ($script:DryRun) { Write-Info "[dry-run] npx -y skills@latest add $repo --global --agent claude-code --skill * --yes"; continue }
        & npx -y skills@latest add $repo --global --agent claude-code --skill '*' --yes | Out-Host
        if ($LASTEXITCODE -ne 0) { Write-Warn "Skills from $repo failed"; $allOk = $false }
    }
    return $allOk
}

# Windows does not let scripts change the default browser, so open the page.
function Open-DefaultBrowserSettings {
    Start-Unelevated 'ms-settings:defaultapps'
    Add-Todo 'In Default apps, pick Dia and click "Set default"'
    return $true
}
