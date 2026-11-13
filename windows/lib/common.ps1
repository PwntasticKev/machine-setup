# Shared helpers for the Windows setup scripts. Dot-sourced, not executed.

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:Checklist = [System.Collections.Generic.List[string]]::new()

function Write-Step([string]$Message) { Write-Host "`n==> $Message" -ForegroundColor Cyan }
function Write-Info([string]$Message) { Write-Host "    $Message" }
function Write-Warn([string]$Message) { Write-Host "!! $Message" -ForegroundColor Yellow }

function Add-Todo([string]$Item) { $script:Checklist.Add($Item) }

# Runs one step; records failure instead of aborting the whole setup.
function Invoke-Step([string]$Name, [scriptblock]$Action) {
    Write-Step $Name
    try {
        $result = & $Action
        if (@($result) -contains $false) { throw 'step reported failure' }
    } catch {
        Write-Warn "$Name failed: $($_.Exception.Message) (continuing)"
        $script:Failures.Add($Name)
    }
}

# Config lines without comments or blank lines; trailing "# ..." comments removed.
function Get-ConfigLines([string]$Path) {
    Get-Content -LiteralPath $Path |
        ForEach-Object { ($_ -replace '\s+#.*$', '').Trim() } |
        Where-Object { $_ -and -not $_.StartsWith('#') }
}

# Reload PATH so tools installed a moment ago (node, git) can be used.
function Update-SessionPath {
    $machine = [Environment]::GetEnvironmentVariable('Path', 'Machine')
    $user = [Environment]::GetEnvironmentVariable('Path', 'User')
    $env:Path = "$machine;$user"
}

# Start a program or URL as the normal (non-admin) user.
function Start-Unelevated([string]$Target) {
    if ($script:DryRun) { Write-Info "[dry-run] open $Target"; return }
    Start-Process -FilePath 'explorer.exe' -ArgumentList "`"$Target`""
}

function Invoke-Download([string]$Url, [string]$FileName) {
    $path = Join-Path $env:TEMP $FileName
    Write-Info "Downloading $Url"
    $ProgressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $Url -OutFile $path -UseBasicParsing
    return $path
}

# Runs a downloaded installer and waits; returns $true when it exits with 0.
function Invoke-Installer([string]$Path, [string]$Name) {
    $process = Start-Process -FilePath $Path -Wait -PassThru
    if ($process.ExitCode -ne 0) {
        Write-Warn "$Name installer exited with code $($process.ExitCode)"
        return $false
    }
    return $true
}

function Write-Summary {
    Write-Step 'Done'
    if ($script:Failures.Count) {
        Write-Warn 'Steps that failed (re-run setup to retry, it skips what is already installed):'
        $script:Failures | ForEach-Object { Write-Host "    - $_" -ForegroundColor Yellow }
    } else {
        Write-Info 'Every step succeeded.'
    }
    if ($script:Checklist.Count) {
        Write-Step 'Your checklist'
        $script:Checklist | ForEach-Object { Write-Host "    [ ] $_" }
    }
}
