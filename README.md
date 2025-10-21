# font_sharpener

DPI Scaling Fix for Clear Fonts in Windows

Улучшает чёткость шрифтов в Windows через настройку реестра.
По мотивам: https://actika.livejournal.com/5313.html

## Установка и запуск

1) Скачайте файл или клонируйте репозиторий:
```
git clone https://github.com/ваш-репозиторий.git
```

2) Перейдите в папку проекта (или куда вы сохранили файл):
```
cd font_sharpener
```

3) Откройте PowerShell от имени администратора (Win + X → «Терминал Windows (администратор)»).

4) При необходимости разрешите выполнение скриптов:
```
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
```

5) Запустите скрипт:
```
.\Set-DpiScaling.ps1
```

## Что делает скрипт?

1) Создаёт резервные копии текущих значений реестра (добавляя символ «_» к именам ключей):
- DpiScalingVer → DpiScalingVer_
- Win8DpiScaling → Win8DpiScaling_
- LogPixels → LogPixels_
- FontSmoothing → FontSmoothing_

2) Устанавливает новые значения для улучшения масштабирования:
```
DpiScalingVer  = 0x00001000
Win8DpiScaling = 0x00000001
LogPixels      = 0x00000060  # 96 DPI (100%)
FontSmoothing  = 0x00000001  # Включено
```

3) Проверяет, что изменения применились корректно.

## Важно
- Требуются права администратора.
- Для применения изменений может потребоваться выход из системы или перезагрузка.
- Рекомендуется создать точку восстановления системы перед запуском.
