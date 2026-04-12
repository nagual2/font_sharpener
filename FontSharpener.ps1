#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

$RegPath = 'HKCU:\Control Panel\Desktop'
$RegistryKeys = @('DpiScalingVer', 'Win8DpiScaling', 'LogPixels', 'FontSmoothing')
$ValidScalingValues = @(100, 125, 150, 175)

function Get-LogPixelsFromPercent {
    param($Percent)
    switch ($Percent) {
        100 { 96 }
        125 { 120 }
        150 { 144 }
        175 { 168 }
        default { throw "Unsupported scaling percent: $Percent" }
    }
}

function Get-TargetValues {
    param($Percent)
    [ordered]@{
        DpiScalingVer  = 0x00001000
        Win8DpiScaling = 0x00000001
        LogPixels      = Get-LogPixelsFromPercent -Percent $Percent
        FontSmoothing  = 0x00000001
    }
}

function Get-CurrentValues {
    $result = @{}
    foreach ($key in $RegistryKeys) {
        try {
            $item = Get-ItemProperty -Path $RegPath -Name $key -ErrorAction Stop
            $result[$key] = [int]$item.$key
        }
        catch {
            $result[$key] = $null
        }
    }
    return $result
}

function Get-DefaultBackupDirectory {
    $docs = [Environment]::GetFolderPath('MyDocuments')
    if (-not $docs) { $docs = $env:USERPROFILE }
    $dir = Join-Path -Path $docs -ChildPath 'FontSharpener-Backups'
    if (-not (Test-Path -LiteralPath $dir)) {
        $null = New-Item -Path $dir -ItemType Directory -Force
    }
    return $dir
}

function Get-DefaultBackupPath {
    $dir = Get-DefaultBackupDirectory
    $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    return Join-Path -Path $dir -ChildPath "FontSharpener-backup-$stamp.json"
}

function Resolve-BackupFilePath {
    param($InputPath)
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
    param($Path, $CurrentValues, $ScalingPercent)
    $backup = [ordered]@{
        SchemaVersion  = 2
        Created        = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
        ToolVersion    = '2.0.0'
        ComputerName   = $env:COMPUTERNAME
        UserName       = $env:USERNAME
        ScalingPercent = $ScalingPercent
        RegistryPath   = $RegPath
        Values         = $CurrentValues
    }
    $json = $backup | ConvertTo-Json -Depth 5
    Set-Content -LiteralPath $Path -Value $json -Encoding UTF8
}

function Backup-RegistryUnderscore {
    param($CurrentValues)
    foreach ($key in $RegistryKeys) {
        $val = $CurrentValues[$key]
        if ($null -ne $val) {
            New-ItemProperty -Path $RegPath -Name ("{0}_" -f $key) -PropertyType DWord -Value ([int]$val) -Force | Out-Null
        }
    }
}

function Show-PlannedChanges {
    param($Current, $Target)
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

function Show-BackupList {
    $dir = Get-DefaultBackupDirectory
    $backups = Get-ChildItem -Path $dir -Filter "FontSharpener-backup-*.json" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
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

function Apply-RegistryValues {
    param($ValuesToApply)
    foreach ($k in $ValuesToApply.Keys) {
        New-ItemProperty -Path $RegPath -Name $k -PropertyType DWord -Value ([int]$ValuesToApply[$k]) -Force | Out-Null
    }
}

function Test-ValuesApplied {
    param($Expected)
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

function Test-IsAdministrator {
    try {
        $current = [Security.Principal.WindowsIdentity]::GetCurrent()
        $principal = [Security.Principal.WindowsPrincipal]::new($current)
        return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    }
    catch {
        return $false
    }
}

function Invoke-SelfElevation {
    param($BoundParameters)
    if (Test-IsAdministrator) { return }
    Write-Warning 'Elevation required. Relaunching as Administrator...'
    try {
        $hostPath = (Get-Process -Id $PID).Path
        $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"{0}"' -f $PSCommandPath))
        foreach ($p in $BoundParameters.Keys) {
            if ($p -eq 'Verbose') { continue }
            $v = $BoundParameters[$p]
            if ($null -eq $v) { continue }
            if ($v -is [switch]) {
                if ($v.IsPresent) { $args += ("-{0}" -f $p) }
            }
            else {
                $args += ("-{0}" -f $p)
                $args += ('"{0}"' -f $v)
            }
        }
        if ($BoundParameters.ContainsKey('Verbose')) { $args += '-Verbose' }
        Start-Process -FilePath $hostPath -ArgumentList $args -Verb RunAs | Out-Null
        exit 0
    }
    catch {
        Write-Error "Failed to elevate. Please run as Administrator."
        exit 1
    }
}

function Start-FontSharpener {
    [CmdletBinding()]
    param(
        $ScalingPercent = 100,
        [switch]$DryRun,
        [string]$BackupPath,
        [string]$Restore,
        [switch]$Force,
        [switch]$ListBackups,
        [switch]$WhatIf
    )

    Set-StrictMode -Version Latest

    try {
        $ScalingPercent = [int]$ScalingPercent
        if ($ValidScalingValues -notcontains $ScalingPercent) {
            throw "Invalid ScalingPercent: $ScalingPercent. Valid values: $($ValidScalingValues -join ', ')"
        }

        if ($ListBackups) {
            Show-BackupList
            return
        }

        if ($Restore) {
            if (-not (Test-Path -LiteralPath $Restore)) {
                throw "Restore file not found: $Restore"
            }
            $json = Get-Content -LiteralPath $Restore -Raw -Encoding UTF8 | ConvertFrom-Json
            if (-not $json -or -not $json.Values) {
                throw 'Invalid backup file: missing Values section'
            }
            $targetFromBackup = @{}
            foreach ($k in $RegistryKeys) {
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
                return
            }
            if ($WhatIf) {
                Write-Host "[WHATIF] Would restore registry values from backup" -ForegroundColor Cyan
                Show-PlannedChanges -Current $current -Target $targetFromBackup
                return
            }
            Invoke-SelfElevation -BoundParameters $PSBoundParameters
            $backupFile = Resolve-BackupFilePath -InputPath $BackupPath
            Save-BackupToJson -Path $backupFile -CurrentValues $current -ScalingPercent $ScalingPercent
            Backup-RegistryUnderscore -CurrentValues $current
            if (-not $Force) {
                $ans = Read-Host 'Proceed with restore? (Y/N)'
                if ($ans -notmatch '^(?i)y') { Write-Host 'Aborted.'; return }
            }
            Apply-RegistryValues -ValuesToApply $targetFromBackup
            if (-not (Test-ValuesApplied -Expected $targetFromBackup)) {
                throw 'Verification failed after restore'
            }
            Write-Host 'Restore completed successfully.' -ForegroundColor Green
            Write-Host 'Sign out or reboot may be required for changes to apply.' -ForegroundColor Yellow
            return
        }

        $target = Get-TargetValues -Percent $ScalingPercent
        $current = Get-CurrentValues

        $diff = @{}
        foreach ($k in $target.Keys) {
            if ($current[$k] -ne $target[$k]) { $diff[$k] = $target[$k] }
        }

        if ($diff.Count -eq 0) {
            Write-Host "All values already set for ${ScalingPercent}% scaling. No changes needed." -ForegroundColor Green
            return
        }

        if ($DryRun) {
            Write-Host "[DRY-RUN] Scaling: ${ScalingPercent}%" -ForegroundColor Cyan
            Show-PlannedChanges -Current $current -Target $target
            $plannedBackup = Resolve-BackupFilePath -InputPath $BackupPath
            Write-Host "`n[DRY-RUN] Backup would be saved to: $plannedBackup" -ForegroundColor Cyan
            return
        }

        if ($WhatIf) {
            Write-Host "[WHATIF] Would apply ${ScalingPercent}% scaling changes to registry" -ForegroundColor Cyan
            Show-PlannedChanges -Current $current -Target $target
            return
        }

        if (-not $Force) {
            Show-PlannedChanges -Current $current -Target $target
            $ans = Read-Host "Apply ${ScalingPercent}% scaling? (Y/N)"
            if ($ans -notmatch '^(?i)y') { Write-Host 'Aborted.'; return }
        }

        Invoke-SelfElevation -BoundParameters $PSBoundParameters

        $backupPathResolved = Resolve-BackupFilePath -InputPath $BackupPath
        Save-BackupToJson -Path $backupPathResolved -CurrentValues $current -ScalingPercent $ScalingPercent
        Backup-RegistryUnderscore -CurrentValues $current
        Write-Host "Backup created: $backupPathResolved" -ForegroundColor Green

        Apply-RegistryValues -ValuesToApply $diff

        if (-not (Test-ValuesApplied -Expected $target)) {
            throw 'Verification failed. Not all values were applied.'
        }

        Write-Host "`nScaling settings applied: ${ScalingPercent}%" -ForegroundColor Green
        Write-Host 'Sign out or reboot may be required for changes to fully apply.' -ForegroundColor Yellow
    }
    catch {
        Write-Error ("Failed: {0}" -f $_.Exception.Message)
        exit 1
    }
}

# Entry point - parse arguments manually
$paramScalingPercent = 100
$paramDryRun = $false
$paramBackupPath = ''
$paramRestore = ''
$paramForce = $false
$paramListBackups = $false
$paramWhatIf = $false

for ($i = 0; $i -lt $args.Count; $i++) {
    $arg = $args[$i]
    switch -Regex ($arg) {
        '^-ScalingPercent$|^/ScalingPercent$' {
            $i++
            if ($i -lt $args.Count) { $paramScalingPercent = $args[$i] }
        }
        '^-DryRun$|^/DryRun$' { $paramDryRun = $true }
        '^-BackupPath$|^/BackupPath$' {
            $i++
            if ($i -lt $args.Count) { $paramBackupPath = $args[$i] }
        }
        '^-Restore$|^/Restore$' {
            $i++
            if ($i -lt $args.Count) { $paramRestore = $args[$i] }
        }
        '^-Force$|^/Force$' { $paramForce = $true }
        '^-ListBackups$|^/ListBackups$' { $paramListBackups = $true }
        '^-WhatIf$|^/WhatIf$' { $paramWhatIf = $true }
    }
}

Start-FontSharpener `
    -ScalingPercent $paramScalingPercent `
    -DryRun:$paramDryRun `
    -BackupPath $paramBackupPath `
    -Restore $paramRestore `
    -Force:$paramForce `
    -ListBackups:$paramListBackups `
    -WhatIf:$paramWhatIf
