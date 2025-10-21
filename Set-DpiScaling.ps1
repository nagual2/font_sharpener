<#
.SYNOPSIS
    Windows DPI scaling and font clarity adjustment for the current user
.DESCRIPTION
    Backs up existing values under HKCU:\Control Panel\Desktop by creating
    underscore-suffixed copies (e.g., DpiScalingVer_), then sets fixed DWORDs
    to improve font clarity on some systems.

    Keys and values written (DWORD):
      - DpiScalingVer  = 0x00001000
      - Win8DpiScaling = 0x00000001
      - LogPixels      = 0x00000060 (96 DPI)
      - FontSmoothing  = 0x00000001 (enabled)

.PARAMETER Restore
    Not implemented in this script. See README for a manual restore snippet
    that copies the underscore-suffixed backups back to the original names.

.PARAMETER RestoreFrom
    Not implemented. See README for manual restore guidance.

.PARAMETER BackupPath
    Not applicable. Backups are stored in-place in HKCU:\Control Panel\Desktop
    by creating values with a trailing underscore.

.EXAMPLE
    PS> .\Set-DpiScaling.ps1
    Backs up current values (e.g., DpiScalingVer_) and writes the fixed values.

.EXAMPLE
    Manual restore in an elevated PowerShell:
        $regPath = 'HKCU:\Control Panel\Desktop'
        $keys = 'DpiScalingVer','Win8DpiScaling','LogPixels','FontSmoothing'
        foreach ($k in $keys) {
          $b = (Get-ItemProperty -Path $regPath -Name ($k + '_') -ErrorAction SilentlyContinue).($k + '_')
          if ($null -ne $b) { Set-ItemProperty -Path $regPath -Name $k -Type DWORD -Value $b }
        }

.NOTES
    Run in elevated PowerShell. Changes apply to the current user (HKCU) only.
    Sign out and back in, or reboot, to apply changes.
#>

<#
.SYNOPSIS
    Скрипт для настройки параметров масштабирования в реестре
.DESCRIPTION
    1. Создает резервную копию текущих значений реестра (добавляя _ к именам ключей)
    2. Устанавливает новые значения для оптимального масштабирования
.NOTES
    Требует запуска от имени администратора
#>

# Путь к разделу реестра
$regPath = "HKCU:\Control Panel\Desktop"

# Ключи для резервного копирования и настройки
$registryKeys = @(
    "DpiScalingVer",
    "Win8DpiScaling",
    "LogPixels",
    "FontSmoothing"
)

# Новые значения для установки
$newValues = @{
    "DpiScalingVer" = 0x00001000
    "Win8DpiScaling" = 0x00000001
    "LogPixels" = 0x00000060
    "FontSmoothing" = 0x00000001
}

# Функция для создания резервной копии
function Backup-RegistryKeys {
    Write-Host "`nСоздание резервных копий текущих значений..." -ForegroundColor Cyan
    
    foreach ($key in $registryKeys) {
        $originalValue = Get-ItemProperty -Path $regPath -Name $key -ErrorAction SilentlyContinue
        
        if ($originalValue -ne $null) {
            $backupKeyName = $key + "_"
            $originalValueData = $originalValue.$key
            
            # Создаем резервную копию
            Set-ItemProperty -Path $regPath -Name $backupKeyName -Value $originalValueData -Type DWORD -Force
            Write-Host "Резервная копия: $key -> $backupKeyName (Значение: $originalValueData)" -ForegroundColor Green
        } else {
            Write-Host "Ключ $key не найден, резервная копия не создана" -ForegroundColor Yellow
        }
    }
}

# Функция для установки новых значений
function Set-NewRegistryValues {
    Write-Host "`nУстановка новых значений..." -ForegroundColor Cyan
    
    foreach ($key in $newValues.Keys) {
        $value = $newValues[$key]
        Set-ItemProperty -Path $regPath -Name $key -Value $value -Type DWORD -Force
        Write-Host "Установлено: $key = $value" -ForegroundColor Green
    }
}

# Функция для проверки изменений
function Verify-Changes {
    Write-Host "`nПроверка установленных значений..." -ForegroundColor Cyan
    
    foreach ($key in $newValues.Keys) {
        $currentValue = (Get-ItemProperty -Path $regPath -Name $key -ErrorAction SilentlyContinue).$key
        $expectedValue = $newValues[$key]
        
        if ($currentValue -eq $expectedValue) {
            Write-Host "$key - OK (Текущее: $currentValue, Ожидаемое: $expectedValue)" -ForegroundColor Green
        } else {
            Write-Host "$key - ОШИБКА (Текущее: $currentValue, Ожидаемое: $expectedValue)" -ForegroundColor Red
        }
    }
}

# Основной код скрипта
try {
    # Создаем резервные копии
    Backup-RegistryKeys
    
    # Устанавливаем новые значения
    Set-NewRegistryValues
    
    # Проверяем изменения
    Verify-Changes
    
    Write-Host "`nНастройка завершена успешно!`nДля применения изменений может потребоваться выход из системы." -ForegroundColor Green
}
catch {
    Write-Host "`nОшибка при выполнении скрипта: $_" -ForegroundColor Red
    exit 1
}
