# Windows setup. Usually started by install.ps1; can also be run directly:
#   powershell -ExecutionPolicy Bypass -File windows\setup.ps1           install everything
#   powershell -ExecutionPolicy Bypass -File windows\setup.ps1 -DryRun   print what would happen
param([switch]$DryRun)

$ErrorActionPreference = 'Stop'
$script:DryRun = [bool]$DryRun
$script:WindowsDir = $PSScriptRoot
$script:ConfigDir = Join-Path (Split-Path $PSScriptRoot -Parent) 'config'

. (Join-Path $PSScriptRoot 'lib\common.ps1')
. (Join-Path $PSScriptRoot 'lib\winget.ps1')
Get-ChildItem (Join-Path $PSScriptRoot 'steps') -Filter '*.ps1' | ForEach-Object { . $_.FullName }

function Test-Admin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    return ([Security.Principal.WindowsPrincipal]$identity).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Ready {
    if (-not $script:DryRun -and -not (Test-Admin)) {
        Write-Host 'Restarting as administrator (accept the prompt)...'
        $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
        try {
            Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
        } catch {
            Write-Warn 'Admin rights are needed. Run this again and click Yes on the prompt.'
            exit 1
        }
        exit 0
    }
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw 'winget is missing. Update "App Installer" from the Microsoft Store, then run this again.'
    }
    if ($script:DryRun) { Write-Step 'Dry run: nothing will be installed' }
}

function Invoke-Setup {
    Assert-Ready
    Invoke-Step 'Steam (log in when it opens)'   { Install-AndOpenSteam }
    Invoke-Step 'Riot: League of Legends + Valorant' { Start-RiotDownloads }
    Invoke-Step 'Jagex Launcher'                 { Install-JagexLauncher }
    Invoke-Step 'Apps from packages.txt'         { Install-Apps }
    Invoke-Step 'Dia'                            { Install-Dia }
    Invoke-Step 'Claude Code skills'             { Install-Skills }
    Invoke-Step 'Queue Steam games'              { Add-SteamGamesToQueue }
    Invoke-Step 'Default browser: Dia'           { Open-DefaultBrowserSettings }

    Add-Todo 'Log into: Slack, Discord, Spotify, Tailscale, Claude, ChatGPT/Codex, Dia, Docker'
    Add-Todo "Run 'claude' once in a terminal to log into Claude Code"
    Write-Summary
}

try {
    Invoke-Setup
} catch {
    Write-Warn "Setup stopped: $($_.Exception.Message)"
} finally {
    # Keep the elevated window open so the summary or error stays readable.
    if (-not $script:DryRun) { Read-Host "`nPress Enter to close" | Out-Null }
}
