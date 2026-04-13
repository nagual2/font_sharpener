# FontSharpener

[![PowerShell CI](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml/badge.svg)](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> PowerShell-Tool zur Konfiguration von DPI-Skalierung und Schriftglättung in Windows.

**Sprachen:** [English](README.md) | [Русский](README.ru.md) | **Deutsch** (diese Seite)

## Übersicht

FontSharpener ändert Windows-Registry-Einstellungen für DPI-Skalierung und Schriftglättung. Es ist für Benutzer gedacht, die mit verschwommenem oder schlecht skaliertem Text auf High-DPI-Displays oder nach Windows-Updates Probleme haben.

**Wirkungsbereich:** Nur aktueller Benutzer (Registry-Hive `HKCU`). Keine Systemänderungen, keine installierten Dienste.

**Sicherheit:** Doppelte Backup-Strategie (JSON-Dateien + Registry-Kopien mit Unterstrich), Dry-Run-Modus, automatische Rechteerhöhung, idempotente Operationen.

## Schnellstart

```powershell
# Änderungen anzeigen (ohne Anwendung)
.\FontSharpener.ps1 -DryRun

# 100% Skalierung anwenden (Standard)
.\FontSharpener.ps1

# 125% Skalierung ohne Bestätigung anwenden
.\FontSharpener.ps1 -ScalingPercent 125 -Force

# Alle verfügbaren Backups anzeigen
.\FontSharpener.ps1 -ListBackups

# Aus bestimmtem Backup wiederherstellen
.\FontSharpener.ps1 -Restore "C:\Users\IhrName\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json" -Force
```

## Anforderungen

- Windows 10 oder Windows 11
- PowerShell 5.1 oder PowerShell 7+
- Administratorrechte (Skript erhöht automatisch, wenn nötig)

## Installation

1. Laden Sie `FontSharpener.ps1` von der [neuesten Version](https://github.com/nagual2/font_sharpener/releases) herunter
2. Speichern Sie es in einem Verzeichnis Ihrer Wahl
3. Führen Sie PowerShell als Administrator aus (oder lassen Sie das Skript automatisch erhöhen)

## Parameter

| Parameter | Typ | Standard | Beschreibung |
|-----------|-----|----------|--------------|
| `-ScalingPercent` | int | 100 | Ziel-DPI-Skalierung: 100, 125, 150 oder 175 |
| `-DryRun` | switch | - | Änderungen anzeigen ohne Anwendung |
| `-BackupPath` | string | Documents\FontSharpener-Backups\ | Benutzerdefiniertes Backup-Verzeichnis oder Datei |
| `-Restore` | string | - | Pfad zur JSON-Backup-Datei für Wiederherstellung |
| `-Force` | switch | - | Bestätigungsaufforderungen überspringen |
| `-ListBackups` | switch | - | Alle verfügbaren Backups anzeigen und beenden |
| `-WhatIf` | switch | - | Standard-PowerShell-WhatIf-Modus |

## Geänderte Registry-Schlüssel

Alle Änderungen erfolgen in `HKCU:\Control Panel\Desktop`:

| Schlüssel | Wert | Beschreibung |
|-----------|------|--------------|
| `DpiScalingVer` | `0x00001000` (4096) | DPI-Skalierungsstatus-Flag |
| `Win8DpiScaling` | `0x00000001` (1) | Windows-8-Skalierungsverhalten aktivieren |
| `LogPixels` | `96/120/144/168` | DPI-Wert basierend auf `-ScalingPercent` |
| `FontSmoothing` | `0x00000001` (1) | ClearType-Schriftglättung aktivieren |

## Backup und Wiederherstellung

### Automatische Backups

Vor jeder Änderung erstellt das Skript:

1. **JSON-Backup-Datei** (Standard: `%USERPROFILE%\Documents\FontSharpener-Backups\`)
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

2. **Registry-Kopien mit Unterstrich**:
   - `DpiScalingVer` → `DpiScalingVer_`
   - `Win8DpiScaling` → `Win8DpiScaling_`
   - `LogPixels` → `LogPixels_`
   - `FontSmoothing` → `FontSmoothing_`

### Manuelle Wiederherstellung

```powershell
# Verfügbare Backups anzeigen
.\FontSharpener.ps1 -ListBackups

# Aus bestimmtem Backup wiederherstellen
.\FontSharpener.ps1 -Restore "$env:USERPROFILE\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json"
```

Oder manuell über PowerShell:

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

## Versionen in anderen Sprachen

- [English](README.md)
- [Русский](README.ru.md)
- **Deutsch** (diese Seite)

## Fehlerbehebung

### „Die Ausführung von Skripten ist auf diesem System deaktiviert"

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### „Zugriff verweigert" oder Änderungen werden nicht angewendet

Stellen Sie sicher, dass PowerShell als Administrator ausgeführt wird. Das Skript versucht automatisch zu erhöhen, aber in einigen Umgebungen ist manuelles Erhöhen erforderlich.

### Schriften sehen nach Anwendung schlechter aus

Stellen Sie aus einem Backup wieder her:

```powershell
.\FontSharpener.ps1 -ListBackups
.\FontSharpener.ps1 -Restore "<pfad-zum-backup>" -Force
```

Oder melden Sie sich ab und wieder an — einige Änderungen erfordern einen Neustart der Sitzung.

## Mitwirken

Siehe [CONTRIBUTING.md](CONTRIBUTING.md).

## Sicherheit

Siehe [SECURITY.md](SECURITY.md) für Informationen über Sicherheitslücken und Sicherheitsrichtlinien.

## Lizenz

MIT License — siehe [LICENSE](LICENSE).

## Änderungsverlauf

### 2.0.0 (2026-01-15)

- Vereinigte Version, die Set-DpiScaling.ps1 und PR #1-Funktionen kombiniert
- Parameter `-ScalingPercent` (100/125/150/175) hinzugefügt
- Parameter `-DryRun`, `-Force`, `-ListBackups` hinzugefügt
- JSON-Backup-Format mit Schema-Version
- Unterstützung für automatische Rechteerhöhung
- Vollständige PSScriptAnalyzer-Konformität
- Mehrsprachige Dokumentation

### 1.0.0 (2025-06-04)

- Erste Veröffentlichung als Set-DpiScaling.ps1
- Grundlegende Registry-Änderung mit Unterstrich-Backups
