# font_sharpener

DPI Scaling Fix for Clear Fonts in Windows

Улучшает чёткость шрифтов в Windows через настройку реестра. По мотивам: https://actika.livejournal.com/5313.html

## Установка

Склонируйте репозиторий (или просто скачайте файл Set-DpiScaling.ps1):

```bash
git clone <repo-url>
cd font_sharpener
```

## Запуск скрипта

1) Откройте PowerShell от имени администратора (Win + X → «Терминал Windows (администратор)»)
2) При необходимости разрешите выполнение скриптов:

```powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

3) Запустите скрипт:

```powershell
.\Set-DpiScaling.ps1
```

## Что делает скрипт?

1. Создаёт резервные копии текущих значений реестра (добавляя `_` к именам ключей):
   - `DpiScalingVer` → `DpiScalingVer_`
   - `Win8DpiScaling` → `Win8DpiScaling_`
   - `LogPixels` → `LogPixels_`
   - `FontSmoothing` → `FontSmoothing_`

2. Устанавливает новые значения для улучшения масштабирования и чёткости шрифтов:

```reg
DpiScalingVer  = 0x00001000
Win8DpiScaling = 0x00000001
LogPixels      = 0x00000060  ; 96 DPI
FontSmoothing  = 0x00000001  ; Включено
```

3. Проверяет, что изменения применились.

## Важно

- Требуются права администратора.
- После применения изменений может потребоваться перезагрузка или выход из системы.
- Рекомендуется создать точку восстановления системы перед запуском.
