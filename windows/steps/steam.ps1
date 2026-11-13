# Steam: install it first, open it so you can log in, then queue games.

$script:SteamLoginTimeoutSeconds = 1800
$script:SteamPollSeconds = 5
$script:SteamQueueDelaySeconds = 3

function Get-SteamExe {
    $key = 'HKLM:\SOFTWARE\WOW6432Node\Valve\Steam'
    $dir = (Get-ItemProperty -Path $key -ErrorAction SilentlyContinue).InstallPath
    if (-not $dir) { $dir = Join-Path ${env:ProgramFiles(x86)} 'Steam' }
    return Join-Path $dir 'steam.exe'
}

function Install-AndOpenSteam {
    if (-not (Install-WingetPackage -Id 'Valve.Steam')) { return $false }
    $exe = Get-SteamExe
    if (-not $script:DryRun -and -not (Test-Path $exe)) { Write-Warn "steam.exe not found at $exe"; return $false }
    Start-Unelevated $exe
    Write-Info 'Steam is opening. Log in now; installs keep going in the meantime.'
    return $true
}

function Test-SteamLoggedIn {
    $active = (Get-ItemProperty -Path 'HKCU:\Software\Valve\Steam\ActiveProcess' -ErrorAction SilentlyContinue).ActiveUser
    return [bool]($active -and $active -ne 0)
}

function Wait-SteamLogin {
    if ($script:DryRun) { return $true }
    $waited = 0
    while (-not (Test-SteamLoggedIn)) {
        if ($waited -ge $script:SteamLoginTimeoutSeconds) { Write-Warn 'Timed out waiting for a Steam login.'; return $false }
        if ($waited % 60 -eq 0) { Write-Info 'Waiting for you to log into Steam...' }
        Start-Sleep -Seconds $script:SteamPollSeconds
        $waited += $script:SteamPollSeconds
    }
    Write-Info 'Steam login detected.'
    return $true
}

# Games from config/steam-games.txt that run on Windows, as objects with Id and Name.
function Get-WindowsSteamGames {
    foreach ($line in Get-ConfigLines (Join-Path $script:ConfigDir 'steam-games.txt')) {
        $parts = $line -split '\s+', 3
        if (($parts[1] -split ',') -contains 'windows') {
            [pscustomobject]@{ Id = $parts[0]; Name = $parts[2] }
        }
    }
}

function Add-SteamGamesToQueue {
    $games = @(Get-WindowsSteamGames)
    if (-not $games.Count) { Write-Info 'No Steam games are listed for Windows.'; return $true }
    if (-not $script:DryRun -and -not (Test-Path (Get-SteamExe))) {
        Write-Warn 'Steam is not installed, so games cannot be queued.'
        return $false
    }

    if (-not (Wait-SteamLogin)) {
        $games | ForEach-Object { Add-Todo "Install $($_.Name) in Steam: steam://install/$($_.Id)" }
        return $false
    }
    foreach ($game in $games) {
        Write-Info "Queueing $($game.Name) ($($game.Id))"
        Start-Unelevated "steam://install/$($game.Id)"
        if (-not $script:DryRun) { Start-Sleep -Seconds $script:SteamQueueDelaySeconds }
    }
    Add-Todo 'Click Install in each Steam dialog'
    return $true
}
