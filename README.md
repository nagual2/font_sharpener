# FontSharpener

Windows DPI scaling and font smoothing helper. Adjusts registry values to improve font clarity on scaling presets (100/125/150/175%). Based on community guidance and documented registry keys.

Repository contains one script: `FontSharpener.ps1`.

English | Русский (см. ниже)

---

## What it does (EN)
- Backs up your current DPI-related registry values (two ways):
  - Creates a timestamped JSON backup file in Documents/FontSharpener-Backups by default (path configurable with `-BackupPath`).
  - Stores underscore copies in the registry (e.g., `LogPixels_`).
- Applies DPI scaling defaults for the selected preset and enables font smoothing:
  - DpiScalingVer = 0x00001000
  - Win8DpiScaling = 1
  - LogPixels = 96/120/144/168 (for 100/125/150/175%)
  - FontSmoothing = 1
- Verifies changes and suggests signing out or rebooting.

Important:
- This script edits your registry under `HKCU\Control Panel\Desktop`. Use at your own risk.
- Administrator privileges are required to modify the registry. The script will attempt to relaunch elevated; otherwise, it will instruct you to run as Administrator.
- You can always run with `-DryRun` first to see what would change without writing to the registry.

## Requirements
- Windows PowerShell 5.1 or PowerShell 7+
- Run from an elevated PowerShell when applying changes (not required for `-DryRun`).

## Usage
Open PowerShell as Administrator, then run:

- Apply 125% scaling:
  - `powershell` (Windows PowerShell 5.1): `powershell -NoProfile -ExecutionPolicy Bypass -File .\FontSharpener.ps1 -ScalingPercent 125`
  - `pwsh` (PowerShell 7+): `pwsh -NoProfile -ExecutionPolicy Bypass -File .\FontSharpener.ps1 -ScalingPercent 125`

- Dry-run (no changes; shows planned diffs):
  - `pwsh -NoProfile -File .\FontSharpener.ps1 -ScalingPercent 150 -DryRun -Verbose`

- Custom backup directory:
  - `pwsh -File .\FontSharpener.ps1 -ScalingPercent 175 -BackupPath D:\Backups`

- Restore from backup file created by this script:
  - `pwsh -File .\FontSharpener.ps1 -Restore .\FontSharpener-Backups\FontSharpener-backup-20250101-101234.json -Force`

Parameters:
- `-ScalingPercent <100|125|150|175>`: Target scaling preset. Default: 100.
- `-DryRun`: Do not change registry; print planned changes and backup location.
- `-BackupPath <path>`: Directory or file path for the JSON backup. If a directory, a timestamped filename is created.
- `-Restore <path>`: Restore values from a JSON backup created by this script.
- `-Force`: Skip interactive prompts.
- `-Verbose`: Show additional details.

Supported presets and LogPixels mapping:
- 100% -> 96
- 125% -> 120
- 150% -> 144
- 175% -> 168

After applying changes, sign out or reboot to ensure the settings take effect.

---

## Что делает (RU)
- Создаёт резервную копию текущих значений (двумя способами):
  - Пишет JSON-файл с бэкапом (по умолчанию в Документы/FontSharpener-Backups; путь настраивается через `-BackupPath`).
  - Создаёт копии значений с подчёркиванием в реестре (`LogPixels_` и т.п.).
- Применяет значения масштабирования и сглаживания шрифтов для выбранного пресета:
  - DpiScalingVer = 0x00001000
  - Win8DpiScaling = 1
  - LogPixels = 96/120/144/168 (для 100/125/150/175%)
  - FontSmoothing = 1
- Проверяет применённые значения и предлагает выйти из системы или перезагрузиться.

Важно:
- Скрипт изменяет реестр в `HKCU\\Control Panel\\Desktop`. Используйте на свой риск.
- Для записи в реестр требуются права администратора. Скрипт попробует перезапуститься с повышенными правами или подскажет, как запустить «От имени администратора».
- Рекомендуется сначала выполнить `-DryRun` (без изменений) и посмотреть, что будет изменено.

## Требования
- Windows PowerShell 5.1 или PowerShell 7+
- Для применения изменений запустите PowerShell «От имени администратора» (для `-DryRun` не требуется).

## Примеры
- Применить масштаб 125%:
  - `powershell -NoProfile -ExecutionPolicy Bypass -File .\\FontSharpener.ps1 -ScalingPercent 125`
- Пробный запуск (без изменений):
  - `pwsh -NoProfile -File .\\FontSharpener.ps1 -ScalingPercent 150 -DryRun -Verbose`
- Указать папку для резервной копии:
  - `pwsh -File .\\FontSharpener.ps1 -ScalingPercent 175 -BackupPath D:\\Backups`
- Восстановить из ранее созданного файла:
  - `pwsh -File .\\FontSharpener.ps1 -Restore .\\FontSharpener-Backups\\FontSharpener-backup-20250101-101234.json -Force`

Параметры:
- `-ScalingPercent <100|125|150|175>` — целевое масштабирование. По умолчанию 100.
- `-DryRun` — ничего не меняет; показывает планируемые изменения и путь бэкапа.
- `-BackupPath <путь>` — папка или файл для JSON-бэкапа. Если указана папка — имя файла будет с отметкой времени.
- `-Restore <путь>` — восстановление значений из JSON-бэкапа.
- `-Force` — не задавать вопросов (подтверждений).
- `-Verbose` — подробные сообщения.

После применения изменений может потребоваться выход из системы или перезагрузка.
