# FontSharpener

[![PowerShell CI](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml/badge.svg)](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> A PowerShell tool for configuring Windows DPI scaling and font smoothing settings to improve text clarity.

## Overview

FontSharpener modifies Windows registry settings related to DPI scaling and font smoothing. It is designed for users who experience blurry or poorly scaled fonts on high-DPI displays or after certain Windows updates.

**Scope:** Current user only (`HKCU` registry hive). No system-wide changes, no services installed.

**Safety:** Dual backup strategy (JSON files + registry underscore copies), dry-run mode, automatic elevation, idempotent operations.

## Quick Start

```powershell
# Preview changes (no modifications)
.\FontSharpener.ps1 -DryRun

# Apply 100% scaling (default)
.\FontSharpener.ps1

# Apply 125% scaling without prompts
.\FontSharpener.ps1 -ScalingPercent 125 -Force

# List all available backups
.\FontSharpener.ps1 -ListBackups

# Restore from a specific backup
.\FontSharpener.ps1 -Restore "C:\Users\YourName\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json" -Force
```

## Requirements

- Windows 10 or Windows 11
- PowerShell 5.1 or PowerShell 7+
- Administrator rights (script will auto-elevate if needed)

## Installation

1. Download `FontSharpener.ps1` from the [latest release](https://github.com/nagual2/font_sharpener/releases)
2. Save to a directory of your choice
3. Run PowerShell as Administrator (or let the script auto-elevate)

## Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-ScalingPercent` | int | 100 | Target DPI scaling: 100, 125, 150, or 175 |
| `-DryRun` | switch | - | Preview changes without applying |
| `-BackupPath` | string | Documents\FontSharpener-Backups\ | Custom backup directory or file |
| `-Restore` | string | - | Path to JSON backup file to restore from |
| `-Force` | switch | - | Skip confirmation prompts |
| `-ListBackups` | switch | - | Show all available backups and exit |
| `-Verbose` | switch | - | Show detailed operation output |
| `-WhatIf` | switch | - | Standard PowerShell what-if mode |

## Registry Keys Modified

All changes are made under `HKCU:\Control Panel\Desktop`:

| Key | Value | Description |
|-----|-------|-------------|
| `DpiScalingVer` | `0x00001000` (4096) | DPI scaling state flag |
| `Win8DpiScaling` | `0x00000001` (1) | Enable Windows 8-style DPI scaling |
| `LogPixels` | `96/120/144/168` | DPI value based on `-ScalingPercent` |
| `FontSmoothing` | `0x00000001` (1) | Enable ClearType font smoothing |

## Backup and Restore

### Automatic Backups

Before any change, the script creates:

1. **JSON backup file** (default location: `%USERPROFILE%\Documents\FontSharpener-Backups\`)
   ```json
   {
     "SchemaVersion": 2,
     "Created": "2025-01-15T14:30:22",
     "ToolVersion": "2.0.0",
     "ScalingPercent": 100,
     "Values": {
       "DpiScalingVer": 4096,
       "Win8DpiScaling": 1,
       "LogPixels": 96,
       "FontSmoothing": 1
     }
   }
   ```

2. **Registry underscore copies** in the same registry location:
   - `DpiScalingVer` → `DpiScalingVer_`
   - `Win8DpiScaling` → `Win8DpiScaling_`
   - `LogPixels` → `LogPixels_`
   - `FontSmoothing` → `FontSmoothing_`

### Manual Restore

```powershell
# List available backups
.\FontSharpener.ps1 -ListBackups

# Restore from specific backup
.\FontSharpener.ps1 -Restore "$env:USERPROFILE\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json"
```

Or manually via PowerShell:

```powershell
$regPath = 'HKCU:\Control Panel\Desktop'
$keys = 'DpiScalingVer', 'Win8DpiScaling', 'LogPixels', 'FontSmoothing'
foreach ($k in $keys) {
    $bk = Get-ItemProperty -Path $regPath -Name "${k}_" -ErrorAction SilentlyContinue
    if ($bk) {
        Set-ItemProperty -Path $regPath -Name $k -Value $bk."${k}_"
    }
}
```

## Language Versions

This documentation is available in multiple languages:

- [English](README.md) (this file)
- [Русский](README.ru.md)

## Troubleshooting

### "Running scripts is disabled on this system"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### "Access is denied" or changes don't apply

Ensure PowerShell is running as Administrator. The script will attempt auto-elevation, but manual elevation may be required in some environments.

### Fonts look worse after applying

Restore from backup:

```powershell
.\FontSharpener.ps1 -ListBackups
.\FontSharpener.ps1 -Restore "<path-to-backup>" -Force
```

Or sign out and back in — some changes require session restart.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## Security

See [SECURITY.md](SECURITY.md) for vulnerability reporting and security policy.

## License

MIT License — see [LICENSE](LICENSE) file.

## Changelog

### 2.0.0 (2026-01-15)

- Unified version combining Set-DpiScaling.ps1 and PR #1 features
- Added `-ScalingPercent` parameter (100/125/150/175)
- Added `-DryRun`, `-Force`, `-ListBackups` parameters
- JSON backup format with schema version
- Automatic elevation support
- Full PSScriptAnalyzer compliance
- Multilingual documentation

### 1.0.0 (2025-06-04)

- Initial release as Set-DpiScaling.ps1
- Basic registry modification with underscore backups
