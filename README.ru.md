# FontSharpener

[![PowerShell CI](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml/badge.svg)](https://github.com/nagual2/font_sharpener/actions/workflows/ci.yml)
[![PowerShell 5.1+](https://img.shields.io/badge/PowerShell-5.1+-blue.svg)](https://docs.microsoft.com/powershell/scripting/install/installing-powershell)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

> Инструмент PowerShell для настройки масштабирования DPI и сглаживания шрифтов в Windows.

**Языки:** [English](README.md) | **Русский** (эта страница) | [Deutsch](README.de.md)

## Обзор

FontSharpener изменяет параметры реестра Windows, связанные с масштабированием DPI и сглаживанием шрифтов. Предназначен для пользователей, которые сталкиваются с размытым или плохо масштабированным текстом на дисплеях с высоким DPI или после обновлений Windows.

**Область действия:** Только текущий пользователь (куст реестра `HKCU`). Никаких системных изменений, никаких установленных служб.

**Безопасность:** Двойная стратегия резервного копирования (JSON-файлы + копии с подчёркиванием в реестре), режим пробного запуска, автоматическое повышение прав, идемпотентные операции.

## Быстрый старт

```powershell
# Предварительный просмотр изменений (без модификаций)
.\FontSharpener.ps1 -DryRun

# Применить масштабирование 100% (по умолчанию)
.\FontSharpener.ps1

# Применить масштабирование 125% без запросов
.\FontSharpener.ps1 -ScalingPercent 125 -Force

# Показать все доступные резервные копии
.\FontSharpener.ps1 -ListBackups

# Восстановить из конкретной резервной копии
.\FontSharpener.ps1 -Restore "C:\Users\YourName\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json" -Force
```

## Требования

- Windows 10 или Windows 11
- PowerShell 5.1 или PowerShell 7+
- Права администратора (скрипт автоматически повысит привилегии при необходимости)

## Установка

1. Скачайте `FontSharpener.ps1` из [последнего релиза](https://github.com/nagual2/font_sharpener/releases)
2. Сохраните в директорию по вашему выбору
3. Запустите PowerShell от имени администратора (или позвольте скрипту автоматически повысить права)

## Параметры

| Параметр | Тип | По умолчанию | Описание |
|----------|-----|--------------|----------|
| `-ScalingPercent` | int | 100 | Целевое масштабирование DPI: 100, 125, 150 или 175 |
| `-DryRun` | switch | - | Предпросмотр изменений без применения |
| `-BackupPath` | string | Documents\FontSharpener-Backups\ | Кастомная директория или файл для резервной копии |
| `-Restore` | string | - | Путь к JSON-файлу резервной копии для восстановления |
| `-Force` | switch | - | Пропустить запросы подтверждения |
| `-ListBackups` | switch | - | Показать все доступные резервные копии и выйти |
| `-Verbose` | switch | - | Показать детальный вывод операций |
| `-WhatIf` | switch | - | Стандартный PowerShell-режим WhatIf |

## Изменяемые ключи реестра

Все изменения производятся в `HKCU:\Control Panel\Desktop`:

| Ключ | Значение | Описание |
|------|----------|----------|
| `DpiScalingVer` | `0x00001000` (4096) | Флаг состояния масштабирования DPI |
| `Win8DpiScaling` | `0x00000001` (1) | Включить стиль масштабирования Windows 8 |
| `LogPixels` | `96/120/144/168` | Значение DPI на основе `-ScalingPercent` |
| `FontSmoothing` | `0x00000001` (1) | Включить сглаживание шрифтов ClearType |

## Резервное копирование и восстановление

### Автоматические резервные копии

Перед любым изменением скрипт создаёт:

1. **JSON-файл резервной копии** (по умолчанию: `%USERPROFILE%\Documents\FontSharpener-Backups\`)
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

2. **Копии с подчёркиванием в реестре**:
   - `DpiScalingVer` → `DpiScalingVer_`
   - `Win8DpiScaling` → `Win8DpiScaling_`
   - `LogPixels` → `LogPixels_`
   - `FontSmoothing` → `FontSmoothing_`

### Ручное восстановление

```powershell
# Показать доступные резервные копии
.\FontSharpener.ps1 -ListBackups

# Восстановить из конкретной копии
.\FontSharpener.ps1 -Restore "$env:USERPROFILE\Documents\FontSharpener-Backups\FontSharpener-backup-20250115-143022.json"
```

Или вручную через PowerShell:

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

## Версии на других языках

- [English](README.md)
- [Русский](README.ru.md) (этот файл)
- [Deutsch](README.de.md)

## Устранение неполадок

### «Выполнение скриптов запрещено в этой системе»

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

### «Отказано в доступе» или изменения не применяются

Убедитесь, что PowerShell запущен от имени администратора. Скрипт попытается автоматически повысить привилегии, но в некоторых средах может потребоваться ручное повышение.

### Шрифты выглядят хуже после применения

Восстановите из резервной копии:

```powershell
.\FontSharpener.ps1 -ListBackups
.\FontSharpener.ps1 -Restore "<путь-к-копии>" -Force
```

Или выйдите из системы и войдите снова — некоторые изменения требуют перезапуска сессии.

## Участие в разработке

См. [CONTRIBUTING.md](CONTRIBUTING.md).

## Безопасность

См. [SECURITY.md](SECURITY.md) для информации об уязвимостях и политике безопасности.

## Лицензия

MIT License — см. файл [LICENSE](LICENSE).

## История изменений

### 2.0.0 (2026-01-15)

- Объединённая версия, объединяющая Set-DpiScaling.ps1 и функции PR #1
- Добавлен параметр `-ScalingPercent` (100/125/150/175)
- Добавлены параметры `-DryRun`, `-Force`, `-ListBackups`
- Формат JSON-резервных копий с версией схемы
- Поддержка автоматического повышения прав
- Полное соответствие PSScriptAnalyzer
- Мультиязычная документация

### 1.0.0 (2025-06-04)

- Первый релиз как Set-DpiScaling.ps1
- Базовое изменение реестра с резервными копиями через подчёркивание
