# Участие в font_sharpener

**Языки:** [English](CONTRIBUTING.md) | **Русский** (эта страница) | [Deutsch](CONTRIBUTING.de.md)

Благодарим за интерес к участию в проекте! Этот документ содержит рекомендации по безопасному участию.

## Начало работы

1. **Создайте форк** репозитория на GitHub
2. **Клонируйте форк** локально:
   ```bash
   git clone git@github.com:ВАШ_ЛОГИН/font_sharpener.git
   cd font_sharpener
   ```
3. **Создайте ветку фичи:**
   ```bash
   git checkout -b feature/название-фичи
   ```

## Настройка окружения

### Требования

- Windows PowerShell 5.0 или новее
- Git 2.30+
- Опционально: pre-commit framework

### Pre-commit hooks

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Руководства по безопасности

**ВАЖНО:** Проект изменяет реестр Windows. Безопасность превыше всего.

### ✅ Делайте:

- Тщательно тестируйте в безопасной среде
- Документируйте все изменения реестра
- Комментируйте сложные операции
- Проверяйте обратную совместимость
- Следуйте лучшим практикам PowerShell
- Обрабатывайте ошибки последовательно

### ❌ Не делайте:

- Не коммитьте пароли и токены
- Не хардкодьте API-ключи
- Не добавляйте внешние зависимости без ревью
- Не модифицируйте .git/config с токенами
- Не включайте персональные данные
- Не пропускайте обработку ошибок

## Стиль кода

### PowerShell

```powershell
# Используйте понятные имена
$registryKeys = @( "DpiScalingVer", "Win8DpiScaling", "LogPixels", "FontSmoothing" )

# Отступы — 4 пробела
function Backup-RegistryKeys {
    foreach ($key in $registryKeys) {
        # Код здесь
    }
}

# Комментируйте сложную логику
# Метод бэкапа: создаём копии с подчёркиванием
Set-ItemProperty -Path $regPath -Name "$($key)_" -Value $originalValue

Write-Host "Backup created: $key -> $($key)_" -ForegroundColor Green
```

## Сообщения коммитов

```
fix: prevent DPI scaling regression on Windows 10
docs: update troubleshooting section
test: verify backup/restore functionality
refactor: improve error handling
```

## Процесс Pull Request

1. Обновите документацию при необходимости
2. Тщательно протестируйте
3. Проверьте отсутствие секретов
4. Опишите PR чётко:
   - Что изменилось?
   - Почему?
   - Как протестировать?
5. Свяжите с issue при необходимости

## Лицензия

Участвуя, вы соглашаетесь лицензировать вклад под той же лицензией, что и проект.
