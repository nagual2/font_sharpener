# font_sharpener
DPI Scaling Fix for Clear Fonts in Windows
Улучшает чёткость шрифтов в Windows через настройку реестра.
По мотивам https://actika.livejournal.com/5313.html


Склонируйте репозиторий или скачайте файл Set-DpiScaling.ps1:
sh
git clone https://github.com/ваш-репозиторий.git


Перейдите в папку с скриптом:

sh
cd registry-dpi-scaling-tool


Запуск скрипта

Откройте PowerShell от имени администратора

(Нажмите Win + X → "Терминал Windows (администратор)")


Разрешите выполнение скриптов (если нужно):

powershell
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
Запустите скрипт:

powershell
.\Set-DpiScaling.ps1


Что делает скрипт?
Создает резервные копии текущих значений реестра (добавляя _ к именам ключей):

DpiScalingVer → DpiScalingVer_

Win8DpiScaling → Win8DpiScaling_

LogPixels → LogPixels_

FontSmoothing → FontSmoothing_

Устанавливает новые значения для улучшения масштабирования:

reg
DpiScalingVer    = 0x00001000
Win8DpiScaling   = 0x00000001
LogPixels        = 0x00000060 (96 DPI)
FontSmoothing    = 0x00000001 (Включено)
Проверяет, что изменения применились.

Важно!
Требуются права администратора
После применения изменений может потребоваться перезагрузка
Рекомендуется создать точку восстановления системы перед запуском



