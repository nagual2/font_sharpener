# font_sharpener

DPI Scaling Fix for Clear Fonts in Windows

Утилита на PowerShell для улучшения чёткости шрифтов в Windows через настройку реестра. Скрипт делает резервную копию текущих значений и применяет оптимальные параметры масштабирования.

Основано на идеях: https://actika.livejournal.com/5313.html

## Быстрый старт

1) Откройте PowerShell от имени администратора (Win + X → «Терминал Windows (администратор)»)
2) При необходимости разрешите выполнение локальных скриптов:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

3) Скачайте файл `Set-DpiScaling.ps1` (или клонируйте репозиторий) и запустите его из папки со скриптом:

```powershell
.\Set-DpiScaling.ps1
```

После выполнения скрипт сообщит о статусе. Для применения может потребоваться выход из системы или перезагрузка.

## Что делает скрипт

- Создаёт резервные копии значений (с суффиксом `_`):
  - `DpiScalingVer_`, `Win8DpiScaling_`, `LogPixels_`, `FontSmoothing_`
- Устанавливает новые значения:

```reg
DpiScalingVer    = 0x00001000
Win8DpiScaling   = 0x00000001
LogPixels        = 0x00000060  ; 96 DPI
FontSmoothing    = 0x00000001  ; включено
```

## Важно

- Требуются права администратора
- Рекомендуется создать точку восстановления системы
- Применение может потребовать перезагрузки

## Восстановление

Скрипт создаёт резервные значения с суффиксом `_`. Для ручного отката можно вернуть исходные значения:

```powershell
$regPath = "HKCU:\Control Panel\Desktop"
$keys = 'DpiScalingVer','Win8DpiScaling','LogPixels','FontSmoothing'
foreach ($k in $keys) {
  $backup = (Get-ItemProperty -Path $regPath -Name ($k + '_') -ErrorAction SilentlyContinue).($k + '_')
  if ($null -ne $backup) { Set-ItemProperty -Path $regPath -Name $k -Value $backup -Type DWord -Force }
}
```

Используйте на свой страх и риск. Автор не несёт ответственности за возможные последствия.
