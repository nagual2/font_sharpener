# font_sharpener
DPI Scaling Fix for Clear Fonts in Windows
Улучшает чёткость шрифтов в Windows через настройку реестра.
По мотивам https://actika.livejournal.com/5313.html

Установка

Склонируйте репозиторий или скачайте файл Set-DpiScaling.ps1:

```
git clone https://github.com/ваш-репозиторий.git
cd font_sharpener
```

Запуск скрипта

Откройте PowerShell от имени администратора (Win + X → "Терминал Windows (администратор)").

Разрешите выполнение скриптов (если нужно):

```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

Запустите скрипт:

```
.\Set-DpiScaling.ps1
```

Что делает скрипт?

- Создает резервные копии текущих значений реестра (добавляя _ к именам ключей):
  - DpiScalingVer → DpiScalingVer_
  - Win8DpiScaling → Win8DpiScaling_
  - LogPixels → LogPixels_
  - FontSmoothing → FontSmoothing_

- Устанавливает новые значения для улучшения масштабирования:

```
DpiScalingVer    = 0x00001000
Win8DpiScaling   = 0x00000001
LogPixels        = 0x00000060 (96 DPI)
FontSmoothing    = 0x00000001 (Включено)
```

- Проверяет, что изменения применились.

Важно!

- Требуются права администратора
- После применения изменений может потребоваться выход из системы или перезагрузка
- Рекомендуется создать точку восстановления системы перед запуском
