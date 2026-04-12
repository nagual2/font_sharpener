#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

<#
.SYNOPSIS
    Configures Windows DPI scaling and font smoothing settings for the current user.

.DESCRIPTION
    Adjusts registry values under HKCU:\Control Panel\Desktop to improve font clarity
    and DPI scaling behavior. Supports multiple scaling levels (100%, 125%, 150%, 175%).

    Backup Strategy:
    - JSON backup file with timestamp (default: Documents\FontSharpener-Backups\)
    - Registry underscore-suffixed values (e.g., DpiScalingVer_)

    Safety Features:
    - Automatic elevation if not running as Administrator
    - -DryRun mode to preview changes without applying
    - Idempotent: skips if values already match target
    - Transaction-safe with verification after changes

.PARAMETER ScalingPercent
    Target DPI scaling percentage. Valid values: 100, 125, 150, 175.
    Default: 100 (96 DPI)

.PARAMETER DryRun
    Preview planned changes without modifying the registry.

.PARAMETER BackupPath
    Custom directory or file path for JSON backup.
    Default: %USERPROFILE%\Documents\FontSharpener-Backups\

.PARAMETER Restore
    Path to a previously created JSON backup file to restore from.

.PARAMETER Force
    Skip interactive confirmation prompts.

.PARAMETER ListBackups
    Display all available JSON backups and exit.

.EXAMPLE
    .\FontSharpener.ps1
    Apply default 100% scaling with interactive confirmation.

.EXAMPLE
    .\FontSharpener.ps1 -ScalingPercent 125 -Force
    Apply 125% scaling without prompts.

.EXAMPLE
    .\FontSharpener.ps1 -DryRun -Verbose
    Preview changes for default scaling with detailed output.

.EXAMPLE
    .\FontSharpener.ps1 -Restore "C:\Backups\FontSharpener-backup-20250115-143022.json" -Force
    Restore registry values from a specific backup.

.EXAMPLE
    .\FontSharpener.ps1 -ListBackups
    Show all available backup files.

.NOTES
    File Name      : FontSharpener.ps1
    Author         : nagual2
    Prerequisite   : PowerShell 5.1 or later, Administrator rights
    Version        : 2.0.0

    Registry Keys Modified:
    - DpiScalingVer  : DWORD 0x00001000 (DPI scaling state flag)
    - Win8DpiScaling : DWORD 0x00000001 (Windows 8 scaling behavior)
    - LogPixels      : DWORD 96/120/144/168 (DPI value based on ScalingPercent)
    - FontSmoothing  : DWORD 0x00000001 (ClearType enabled)

    Change History:
    - 2.0.0: Unified version combining Set-DpiScaling.ps1 and PR #1 features
    - 1.1.0: Added multi-language support (EN/RU/DE documentation)
    - 1.0.0: Initial release (Set-DpiScaling.ps1)

.LINK
    https://github.com/nagual2/font_sharpener
#>

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'Scaling percent: 100, 125, 150, 175')]
    [ValidateSet(100, 125, 150, 175)]
    [int]$ScalingPercent = 100,

    [Parameter(HelpMessage = 'Preview changes without applying')]
    [switch]$DryRun,

    [Parameter(HelpMessage = 'Custom backup directory or file path')]
    [string]$BackupPath,

    [Parameter(HelpMessage = 'Restore from JSON backup file')]
    [string]$Restore,

    [Parameter(HelpMessage = 'Skip confirmation prompts')]
    [switch]$Force,

    [Parameter(HelpMessage = 'List available backups and exit')]
    [switch]$ListBackups
)

#region Constants
$script:RegPath = 'HKCU:\Control Panel\Desktop'
$script:RegistryKeys = @('DpiScalingVer', 'Win8DpiScaling', 'LogPixels', 'FontSmoothing')
$script:Version = '2.0.0'
#endregion

#region Helper Functions
function Test-IsAdministrator {
    <#.SYNOPSIS Check if running with elevated privileges.#>
    try {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($current)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        Write-Error "Failed to determine elevation state: $($_.Exception.Message)"
        return $false
    }
}

function Get-LogPixelsFromPercent {
    <#.SYNOPSIS Convert scaling percentage to LogPixels value.#>
    param([ValidateSet(100, 125, 150, 175)][int]$Percent)
    switch ($Percent) {
        100 { 96 }
        125 { 120 }
        150 { 144 }
        175 { 168 }
        default { throw "Unsupported scaling percent: $Percent" }
    }
}

function Get-TargetValues {
    <#.SYNOPSIS Generate registry values for specified scaling percentage.#>
    param([ValidateSet(100, 125, 150, 175)][int]$Percent)
    [ordered]@{
        DpiScalingVer  = 0x00001000
        Win8DpiScaling = 0x00000001
        LogPixels      = Get-LogPixelsFromPercent -Percent $Percent
        FontSmoothing  = 0x00000001
    }
}

function Get-CurrentValues {
    <#.SYNOPSIS Read current registry values.#>
    $result = @{}
    foreach ($key in $script:RegistryKeys) {
        try {
            $item = Get-ItemProperty -Path $script:RegPath -Name $key -ErrorAction Stop
            $result[$key] = [int]$item.$key
        }
        catch {
            $result[$key] = $null
        }
    }
    return $result
}

function Get-DefaultBackupDirectory {
    <#.SYNOPSIS Get or create default backup directory.#>
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = $env:USERPROFILE }
    $dir = Join-Path -Path $docs -ChildPath 'FontSharpener-Backups'
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -Path $dir -ItemType Directory -Force
    }
    return $dir
}

function Get-DefaultBackupPath {
    <#.SYNOPSIS Generate default backup file path with timestamp.#>
    $dir = Get-DefaultBackupDirectory
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    return Join-Path -Path $dir -ChildPath "FontSharpener-backup-$stamp.json"
}

function Resolve-BackupFilePath {
    <#.SYNOPSIS Resolve backup path (directory or file).#>
    param([string]$InputPath)
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        return Get-DefaultBackupPath
    }
    if (Test-Path -LiteralPath $InputPath) {
        $attr = Get-Item -LiteralPath $InputPath
        if ($attr.PSIsContainer) {
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            return Join-Path -Path $InputPath -ChildPath "FontSharpener-backup-$stamp.json"
        }
        return $InputPath
    }
    $parent = Split-Path -Path $InputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($parent) -and -not (Test-Path $parent)) {
        $null = New-Item -Path $parent -ItemType Directory -Force
    }
    return $InputPath
}

function Save-BackupToJson {
    <#.SYNOPSIS Save current registry values to JSON backup file.#>
    param([string]$Path, [hashtable]$CurrentValues)
    $backup = [ordered]@{
        SchemaVersion = 2
        Created       = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        ToolVersion   = $script:Version
        ComputerName  = $env:COMPUTERNAME
        UserName      = $env:USERNAME
        ScalingPercent = $ScalingPercent
        RegistryPath  = $script:RegPath
        Values        = $CurrentValues
    }
    $json = $backup | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
    Write-Verbose "Backup saved: $Path"
}

function Backup-RegistryUnderscore {
    <#.SYNOPSIS Create underscore-suffixed registry backups.#>
    param([hashtable]$CurrentValues)
    foreach ($key in $script:RegistryKeys) {
        $val = $CurrentValues[$key]
        if ($null -ne $val) {
            $backupName = "{0}_" -f $key
            New-ItemProperty -Path $script:RegPath -Name $backupName -PropertyType DWord -Value ([int]$val) -Force | Out-Null
            Write-Verbose "Registry backup: $key -> $backupName = $val"
        }
    }
}

function Show-BackupList {
    <#.SYNOPSIS Display all available JSON backups.#>
    $dir = Get-DefaultBackupDirectory
    $backups = Get-ChildItem -Path $dir -Filter "FontSharpener-backup-*.json" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending
    if (-not $backups) {
        Write-Host "No backups found in: $dir" -ForegroundColor Yellow
        return
    }
    Write-Host "`nAvailable backups:" -ForegroundColor Cyan
    Write-Host ("-" * 60)
    foreach ($b in $backups) {
        $data = Get-Content $b.FullName -Raw | ConvertFrom-Json
        $date = [DateTime]::Parse($data.Created).ToString('yyyy-MM-dd HH:mm')
        $dpi = $data.ScalingPercent
        Write-Host ("  {0,-25} | {1} | {2}% DPI" -f $b.Name, $date, $dpi) -ForegroundColor Green
    }
    Write-Host ("-" * 60)
    Write-Host "Total: $($backups.Count) backup(s) in $dir`n"
}

function Show-PlannedChanges {
    <#.SYNOPSIS Display comparison of current vs target values.#>
    param([hashtable]$Current, [hashtable]$Target)
    Write-Host "`nPlanned changes:" -ForegroundColor Cyan
    foreach ($key in $Target.Keys) {
        $cv = $Current[$key]
        $tv = [int]$Target[$key]
        $cvStr = if ($null -eq $cv) { '(not set)' } else { $cv }
        if ($cv -ne $tv) {
            Write-Host ("  {0,-16}: {1,-12} -> {2}" -f $key, $cvStr, $tv) -ForegroundColor Yellow
        }
        else {
            Write-Host ("  {0,-16}: {1,-12} (no change)" -f $key, $cvStr) -ForegroundColor Green
        }
    }
}

function Apply-RegistryValues {
    <#.SYNOPSIS Apply registry changes.#>
    param([hashtable]$ValuesToApply)
    foreach ($k in $ValuesToApply.Keys) {
        New-ItemProperty -Path $script:RegPath -Name $k -PropertyType DWord -Value ([int]$ValuesToApply[$k]) -Force | Out-Null
        Write-Verbose "Applied: $k = $($ValuesToApply[$k])"
    }
}

function Test-ValuesApplied {
    <#.SYNOPSIS Verify registry values match expected.#>
    param([hashtable]$Expected)
    $curr = Get-CurrentValues
    $allOk = $true
    foreach ($k in $Expected.Keys) {
        $cv = $curr[$k]
        $ev = [int]$Expected[$k]
        if ($cv -ne $ev) {
            Write-Error "Verification failed: $k (Current=$cv, Expected=$ev)"
            $allOk = $false
        }
    }
    return $allOk
}

function Invoke-SelfElevation {
    <#.SYNOPSIS Relaunch script as Administrator if needed.#>
    if (Test-IsAdministrator) { return }
    Write-Warning 'Elevation required. Relaunching as Administrator...'
    try {
        $hostPath = (Get-Process -Id $PID).Path
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
        foreach ($p in $PSBoundParameters.Keys) {
            if ($p -eq 'Verbose') { continue }
            $v = $PSBoundParameters[$p]
            if ($null -eq $v) { continue }
            if ($v -is [switch]) {
                if ($v.IsPresent) { $args += ("-{0}" -f $p) }
            }
            else {
                $args += ("-{0}" -f $p)
                $args += ('"{0}"' -f $v)
            }
        }
        if ($PSBoundParameters.ContainsKey('Verbose')) { $args += '-Verbose' }
        Start-Process -FilePath $hostPath -ArgumentList $args -Verb RunAs | Out-Null
        exit 0
    }
    catch {
        Write-Error "Failed to elevate: $($_.Exception.Message)`nPlease run as Administrator."
        exit 1
    }
}
#endregion

#region Main Logic
try {
    # Handle ListBackups request
    if ($ListBackups) {
        Show-BackupList
        exit 0
    }

    # Handle Restore request
    if ($PSBoundParameters.ContainsKey('Restore') -and -not [string]::IsNullOrWhiteSpace($Restore)) {
        if (-not (Test-Path -LiteralPath $Restore)) {
            throw "Restore file not found: $Restore"
        }
        $json = Get-Content -LiteralPath $Restore -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $json -or -not $json.Values) {
            throw 'Invalid backup file: missing Values section'
        }
        $targetFromBackup = @{}
        foreach ($k in $script:RegistryKeys) {
            if ($null -ne $json.Values.$k) {
                $targetFromBackup[$k] = [int]$json.Values.$k
            }
        }
        if ($targetFromBackup.Count -eq 0) {
            throw 'Backup contains no known registry keys'
        }
        $current = Get-CurrentValues
        if ($DryRun) {
            Write-Host "[DRY-RUN] Would restore from: $Restore" -ForegroundColor Cyan
            Show-PlannedChanges -Current $current -Target $targetFromBackup
            exit 0
        }
        Invoke-SelfElevation
        $backupFile = Resolve-BackupFilePath -InputPath $BackupPath
        Save-BackupToJson -Path $backupFile -CurrentValues $current
        Backup-RegistryUnderscore -CurrentValues $current
        if (-not $Force) {
            $ans = Read-Host 'Proceed with restore? (Y/N)'
            if ($ans -notmatch '^(?i)y') { Write-Host 'Aborted.'; exit 0 }
        }
        Apply-RegistryValues -ValuesToApply $targetFromBackup
        if (-not (Test-ValuesApplied -Expected $targetFromBackup)) {
            throw 'Verification failed after restore'
        }
        Write-Host 'Restore completed successfully.' -ForegroundColor Green
        Write-Host 'Sign out or reboot may be required for changes to apply.' -ForegroundColor Yellow
        exit 0
    }

    # Standard apply flow
    $target = Get-TargetValues -Percent $ScalingPercent
    $current = Get-CurrentValues

    # Check if already applied
    $diff = @{}
    foreach ($k in $target.Keys) {
        if ($current[$k] -ne $target[$k]) { $diff[$k] = $target[$k] }
    }

    if ($diff.Count -eq 0) {
        Write-Host "All values already set for ${ScalingPercent}% scaling. No changes needed." -ForegroundColor Green
        exit 0
    }

    if ($DryRun) {
        Write-Host "[DRY-RUN] Scaling: ${ScalingPercent}%" -ForegroundColor Cyan
        Show-PlannedChanges -Current $current -Target $target
        $plannedBackup = Resolve-BackupFilePath -InputPath $BackupPath
        Write-Host "`n[DRY-RUN] Backup would be saved to: $plannedBackup" -ForegroundColor Cyan
        exit 0
    }

    # Confirm with -WhatIf support
    if (-not $Force -and -not $PSCmdlet.ShouldProcess("HKCU DPI settings (${ScalingPercent}%)", 'Modify')) {
        exit 0
    }

    Invoke-SelfElevation

    # Create backups
    $backupPathResolved = Resolve-BackupFilePath -InputPath $BackupPath
    Save-BackupToJson -Path $backupPathResolved -CurrentValues $current
    Backup-RegistryUnderscore -CurrentValues $current
    Write-Host "Backup created: $backupPathResolved" -ForegroundColor Green

    # Interactive confirmation (unless -Force or -WhatIf)
    if (-not $Force -and -not $WhatIfPreference) {
        Show-PlannedChanges -Current $current -Target $target
        $ans = Read-Host "`nApply ${ScalingPercent}% scaling? (Y/N)"
        if ($ans -notmatch '^(?i)y') { Write-Host 'Aborted.'; exit 0 }
    }

    # Apply changes
    Apply-RegistryValues -ValuesToApply $diff

    # Verify
    if (-not (Test-ValuesApplied -Expected $target)) {
        throw 'Verification failed. Not all values were applied.'
    }

    Write-Host "`nScaling settings applied: ${ScalingPercent}%" -ForegroundColor Green
    Write-Host 'Sign out or reboot may be required for changes to fully apply.' -ForegroundColor Yellow
    exit 0
}
catch {
    Write-Error ("Failed: {0}" -f $_.Exception.Message)
    exit 1
}
#endregion
