# Font Sharpener — Windows DPI scaling and font clarity fix (EN)

A minimal PowerShell script that improves font clarity on some Windows systems by writing a few DPI-related registry values for the current user. It first backs up your current values, then applies a known-good set of defaults.

Based on the approach described here: https://actika.livejournal.com/5313.html

Overview

- Scope: Current user only (HKCU). No services, no installers.
- Flow: Backup current values → apply fixed values → verify → you sign out or reboot.
- Admin rights: Run PowerShell as Administrator.

Registry keys and exact values changed

Path: HKCU\Control Panel\Desktop (DWORD values)

- DpiScalingVer = 0x00001000
- Win8DpiScaling = 0x00000001
- LogPixels = 0x00000060  (96 DPI)
- FontSmoothing = 0x00000001  (enabled)

How backup and restore work

- Backup method (in-place): Before any change, the script reads each value and stores a backup copy with an underscore suffix in the same registry location:
  - DpiScalingVer → DpiScalingVer_
  - Win8DpiScaling → Win8DpiScaling_
  - LogPixels → LogPixels_
  - FontSmoothing → FontSmoothing_
- Default backup location: No external files are created. Backups live alongside the originals in HKCU\Control Panel\Desktop as “valueName_”.
- Restore options (manual): This script does not implement a restore switch. To revert, either use Registry Editor (regedit) to copy the “_” values back to their originals or run the PowerShell snippet below in an elevated window:

```
$regPath = 'HKCU:\Control Panel\Desktop'
$keys = 'DpiScalingVer','Win8DpiScaling','LogPixels','FontSmoothing'
foreach ($k in $keys) {
  $bkName = "${k}_"
  $bkVal = (Get-ItemProperty -Path $regPath -Name $bkName -ErrorAction SilentlyContinue).$bkName
  if ($null -ne $bkVal) {
    Set-ItemProperty -Path $regPath -Name $k -Type DWORD -Value $bkVal
  }
}
```

Usage

1) Open PowerShell as Administrator (Win + X → “Windows Terminal (Admin)”).
2) If needed, allow local scripts:

```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

3) Run the script from the repository folder:

```
.\Set-DpiScaling.ps1
```

Requirements and notes

- Admin privileges are required.
- Changes apply to the current user (HKCU) only.
- Sign out and back in (recommended) or reboot for the changes to fully apply.
- Consider creating a system restore point if you want an additional safety net.

Troubleshooting

- “running scripts is disabled on this system”: set execution policy as shown above.
- “access is denied” or no changes are saved: ensure you launched PowerShell as Administrator.
- Fonts look worse: use the manual restore snippet above to revert the values.
- Keys not present: the script will create the values as needed; the restore step will skip any backups that don’t exist.

FAQ

- What does each value do?
  - DpiScalingVer: internal flag for DPI scaling state.
  - Win8DpiScaling: enables Windows 8-style DPI scaling behavior (1 = on).
  - LogPixels: DPI value (0x60 = 96 decimal).
  - FontSmoothing: enables font smoothing/ClearType (1 = on).
- Does this affect other users? No, only the current user.
- Can I set a different DPI? Not with this script. It always applies the fixed values above.
- Do I need to reboot? A sign-out is usually enough; sometimes a reboot helps.
- Where are backups stored? In the same registry path as underscore-suffixed values. No external backup files are created.


# Font Sharpener — исправление масштабирования DPI и чёткости шрифтов (RU)

Минимальный PowerShell-скрипт, который улучшает чёткость шрифтов на некоторых системах Windows. Он сохраняет резервную копию текущих значений, затем применяет проверенный набор параметров масштабирования для текущего пользователя.

Основано на подходе из: https://actika.livejournal.com/5313.html

Обзор

- Область действия: только текущий пользователь (HKCU). Без служб и установщиков.
- Последовательность: Резервное копирование текущих значений → примем фиксированные значения → проверка → выход из системы или перезагрузка.
- Права: запускать PowerShell от имени администратора.

Изменяемые ключи реестра и точные значения

Раздел: HKCU\Control Panel\Desktop (DWORD)

- DpiScalingVer = 0x00001000
- Win8DpiScaling = 0x00000001
- LogPixels = 0x00000060  (96 DPI)
- FontSmoothing = 0x00000001  (включено)

Как работает резервное копирование и восстановление

- Метод резервного копирования (в том же разделе): Перед изменениями скрипт сохраняет исходные значения с суффиксом подчёркивания в том же разделе реестра:
  - DpiScalingVer → DpiScalingVer_
  - Win8DpiScaling → Win8DpiScaling_
  - LogPixels → LogPixels_
  - FontSmoothing → FontSmoothing_
- Путь резервной копии по умолчанию: внешние файлы не создаются. Копии хранятся рядом с исходными значениями в HKCU\Control Panel\Desktop под именами с «_» на конце.
- Восстановление (вручную): В этом скрипте нет отдельного переключателя восстановления. Чтобы вернуть всё как было, используйте Редактор реестра (regedit) и перепишите значения из «_» обратно, либо выполните фрагмент PowerShell ниже в повышенной консоли:

```
$regPath = 'HKCU:\Control Panel\Desktop'
$keys = 'DpiScalingVer','Win8DpiScaling','LogPixels','FontSmoothing'
foreach ($k in $keys) {
  $bkName = "${k}_"
  $bkVal = (Get-ItemProperty -Path $regPath -Name $bkName -ErrorAction SilentlyContinue).$bkName
  if ($null -ne $bkVal) {
    Set-ItemProperty -Path $regPath -Name $k -Type DWORD -Value $bkVal
  }
}
```

Использование

1) Откройте PowerShell от имени администратора (Win + X → «Windows Terminal (администратор)»).
2) При необходимости разрешите запуск локальных скриптов:

```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

3) Запустите скрипт из папки репозитория:

```
.\Set-DpiScaling.ps1
```

Требования и примечания

- Нужны права администратора.
- Изменения применяются только к текущему пользователю (HKCU).
- Для полного применения рекомендуются выход из системы и вход снова; иногда нужна перезагрузка.
- Для надёжности можно создать точку восстановления системы.

Устранение неполадок

- «запуск скриптов запрещён»: установите политику выполнения, как показано выше.
- «access is denied» или изменения не сохраняются: убедитесь, что PowerShell запущен от имени администратора.
- Шрифты стали хуже: воспользуйтесь фрагментом восстановления выше.
- Ключей нет: скрипт создаст нужные значения; при восстановлении будут пропущены отсутствующие резервные копии.

FAQ

- Что делает каждый параметр?
  - DpiScalingVer: внутренний флаг состояния масштабирования DPI.
  - Win8DpiScaling: включает стиль масштабирования Windows 8 (1 = вкл.).
  - LogPixels: значение DPI (0x60 = 96 десятичное).
  - FontSmoothing: сглаживание шрифтов/ClearType (1 = вкл.).
- Влияет ли на других пользователей? Нет, только на текущего.
- Можно ли задать другой DPI? В этом скрипте — нет. Он всегда применяет фиксированные значения выше.
- Нужна ли перезагрузка? Обычно достаточно выхода из системы; иногда помогает перезагрузка.
- Где хранятся резервные копии? В том же разделе реестра, значения с суффиксом подчёркивания. Внешние файлы не создаются.
