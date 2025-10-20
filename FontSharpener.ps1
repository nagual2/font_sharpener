#Requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $false, HelpMessage = 'Scaling percent to apply. Supported: 100, 125, 150, 175')]
    [ValidateSet(100,125,150,175)]
    [int]
    $ScalingPercent = 100,

    [Parameter()]
    [switch]
    $DryRun,

    [Parameter(HelpMessage = 'Directory or file path to save backup. If directory, a timestamped filename will be created.')]
    [string]
    $BackupPath,

    [Parameter(HelpMessage = 'Path to a previously created backup file to restore (JSON created by this script).')]
    [string]
    $Restore,

    [Parameter(HelpMessage = 'Skip interactive prompts.')]
    [switch]
    $Force
)

# Constant registry path and keys
$RegPath = 'HKCU:\Control Panel\Desktop'
$RegistryKeys = @('DpiScalingVer','Win8DpiScaling','LogPixels','FontSmoothing')

function Test-IsAdministrator {
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

function Get-TargetValues {
    param(
        [Parameter(Mandatory)]
        [ValidateSet(100,125,150,175)]
        [int] $Percent
    )

    $logPixels = switch ($Percent) {
        100 { 96 }
        125 { 120 }
        150 { 144 }
        175 { 168 }
        default { throw "Unsupported scaling percent: $Percent" }
    }

    [ordered]@{
        DpiScalingVer  = 0x00001000
        Win8DpiScaling = 0x00000001
        LogPixels      = [int]$logPixels
        FontSmoothing  = 0x00000001
    }
}

function Get-CurrentValues {
    $result = @{}
    foreach ($k in $RegistryKeys) {
        try {
            $item = Get-ItemProperty -Path $RegPath -Name $k -ErrorAction Stop
            $result[$k] = [int]($item.$k)
        }
        catch {
            $result[$k] = $null
        }
    }
    return $result
}

function Ensure-BackupDirectory {
    param(
        [string] $Path
    )
    if (-not (Test-Path -LiteralPath $Path)) {
        $null = New-Item -Path $Path -ItemType Directory -Force
    }
}

function Get-DefaultBackupPath {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = $env:USERPROFILE }
    $dir = Join-Path -Path $docs -ChildPath 'FontSharpener-Backups'
    Ensure-BackupDirectory -Path $dir
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    return (Join-Path -Path $dir -ChildPath ("FontSharpener-backup-$stamp.json"))
}

function Resolve-BackupFilePath {
    param(
        [string] $InputPath
    )
    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        return Get-DefaultBackupPath
    }

    if (Test-Path -LiteralPath $InputPath) {
        $attr = Get-Item -LiteralPath $InputPath
        if ($attr.PSIsContainer) {
            Ensure-BackupDirectory -Path $InputPath
            $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
            return (Join-Path -Path $InputPath -ChildPath ("FontSharpener-backup-$stamp.json"))
        }
        else {
            return $InputPath
        }
    }

    $parent = Split-Path -Path $InputPath -Parent
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        Ensure-BackupDirectory -Path $parent
    }
    return $InputPath
}

function Save-Backup {
    param(
        [string] $Path,
        [hashtable] $CurrentValues
    )
    $backup = [ordered]@{
        Created       = (Get-Date).ToString('s')
        ComputerName  = $env:COMPUTERNAME
        UserName      = $env:USERNAME
        RegistryPath  = $RegPath
        Values        = $CurrentValues
    }

    $json = $backup | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
    Write-Verbose "Backup saved to: $Path"
}

function Backup-RegistryUnderscoreCopies {
    param(
        [hashtable] $CurrentValues
    )
    foreach ($key in $RegistryKeys) {
        $val = $CurrentValues[$key]
        if ($null -ne $val) {
            New-ItemProperty -Path $RegPath -Name ("{0}_" -f $key) -PropertyType DWord -Value ([int]$val) -Force | Out-Null
        }
    }
}

function Apply-Values {
    param(
        [hashtable] $ValuesToApply
    )
    foreach ($k in $ValuesToApply.Keys) {
        New-ItemProperty -Path $RegPath -Name $k -PropertyType DWord -Value ([int]$ValuesToApply[$k]) -Force | Out-Null
    }
}

function Verify-Values {
    param(
        [hashtable] $Expected
    )
    $curr = Get-CurrentValues
    $ok = $true
    foreach ($k in $Expected.Keys) {
        $cv = $curr[$k]
        $ev = [int]$Expected[$k]
        if ($cv -ne $ev) {
            Write-Error "Verification failed for $k. Current=$cv Expected=$ev"
            $ok = $false
        }
    }
    return $ok
}

function Show-PlannedChanges {
    param(
        [hashtable] $Current,
        [hashtable] $Target
    )
    Write-Output 'Planned changes:'
    foreach ($k in $Target.Keys) {
        $cv = $Current[$k]
        $ev = [int]$Target[$k]
        if ($cv -ne $ev) {
            Write-Output (" - {0}: {1} -> {2}" -f $k, ($cv -as [string]), $ev)
        }
        else {
            Write-Output (" - {0}: already {1}" -f $k, $ev)
        }
    }
}

function Invoke-SelfElevationIfNeeded {
    if (Test-IsAdministrator) { return }

    Write-Warning 'This script is not running elevated. Attempting to relaunch as Administrator...'

    try {
        $hostPath = (Get-Process -Id $PID).Path
        $args = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
        foreach ($name in $PSBoundParameters.Keys) {
            if ($name -eq 'Verbose') { continue }
            $value = $PSBoundParameters[$name]
            if ($null -eq $value) { continue }
            if ($value -is [switch]) {
                if ($value.IsPresent) { $args += ('-{0}' -f $name) }
            }
            else {
                $args += ('-{0}' -f $name)
                $args += ('"{0}"' -f $value)
            }
        }
        if ($PSBoundParameters.ContainsKey('Verbose')) { $args += '-Verbose' }

        Start-Process -FilePath $hostPath -ArgumentList $args -Verb RunAs | Out-Null
        Write-Output 'Relaunched with elevation. This instance will exit.'
        exit 0
    }
    catch {
        Write-Error "Failed to relaunch elevated: $($_.Exception.Message). Please run this script from an elevated PowerShell (Run as Administrator)."
        exit 1
    }
}

try {
    if ($PSBoundParameters.ContainsKey('Restore') -and -not [string]::IsNullOrWhiteSpace($Restore)) {
        $restorePath = $Restore
        if (-not (Test-Path -LiteralPath $restorePath)) {
            throw "Restore file not found: $restorePath"
        }

        $json = Get-Content -LiteralPath $restorePath -Raw -Encoding UTF8 | ConvertFrom-Json
        if (-not $json -or -not $json.Values) {
            throw 'Restore file is invalid or missing Values section.'
        }

        $targetFromBackup = @{}
        foreach ($k in $RegistryKeys) {
            if ($null -ne $json.Values.$k) {
                $targetFromBackup[$k] = [int]$json.Values.$k
            }
        }
        if ($targetFromBackup.Keys.Count -eq 0) {
            throw 'Restore file does not contain any known keys to restore.'
        }

        $current = Get-CurrentValues
        if ($DryRun) {
            Write-Output ("[DRY-RUN] Would restore registry values from backup: {0}" -f $restorePath)
            Show-PlannedChanges -Current $current -Target $targetFromBackup
            exit 0
        }

        Invoke-SelfElevationIfNeeded

        $backupFile = Resolve-BackupFilePath -InputPath $BackupPath
        Save-Backup -Path $backupFile -CurrentValues $current
        Backup-RegistryUnderscoreCopies -CurrentValues $current

        if (-not $Force) {
            $answer = Read-Host 'Proceed to restore values from backup? (Y/N)'
            if ($answer -notmatch '^(?i)y') { Write-Output 'Aborted by user.'; exit 0 }
        }

        Apply-Values -ValuesToApply $targetFromBackup
        if (-not (Verify-Values -Expected $targetFromBackup)) {
            throw 'Verification after restore failed.'
        }

        Write-Output 'Restore completed successfully.'
        Write-Output 'A sign out or reboot may be required for changes to fully apply.'
        exit 0
    }

    $target = Get-TargetValues -Percent $ScalingPercent
    $currentValues = Get-CurrentValues

    $diff = @{}
    foreach ($k in $target.Keys) {
        if ($currentValues[$k] -ne $target[$k]) { $diff[$k] = $target[$k] }
    }

    if ($DryRun) {
        Write-Output ("[DRY-RUN] Scaling Percent: {0}%" -f $ScalingPercent)
        Show-PlannedChanges -Current $currentValues -Target $target
        $plannedBackup = Resolve-BackupFilePath -InputPath $BackupPath
        Write-Output ("[DRY-RUN] A backup would be saved to: {0}" -f $plannedBackup)
        exit 0
    }

    if ($diff.Count -eq 0) {
        Write-Output 'All target values are already applied. No changes necessary.'
        exit 0
    }

    Invoke-SelfElevationIfNeeded

    $backupPathResolved = Resolve-BackupFilePath -InputPath $BackupPath
    Save-Backup -Path $backupPathResolved -CurrentValues $currentValues
    Backup-RegistryUnderscoreCopies -CurrentValues $currentValues

    if (-not $Force) {
        Write-Output ("The following changes will be applied for scaling {0}%:" -f $ScalingPercent)
        Show-PlannedChanges -Current $currentValues -Target $target
        $answer2 = Read-Host 'Proceed? (Y/N)'
        if ($answer2 -notmatch '^(?i)y') { Write-Output 'Aborted by user.'; exit 0 }
    }

    Apply-Values -ValuesToApply $diff

    if (-not (Verify-Values -Expected $target)) {
        throw 'Verification failed. Not all values were applied.'
    }

    Write-Output ("Scaling settings applied successfully for {0}%" -f $ScalingPercent)
    Write-Output 'A sign out or reboot may be required for changes to fully apply.'
    exit 0
}
catch {
    Write-Error ("Failure: {0}" -f $_.Exception.Message)
    exit 1
}
