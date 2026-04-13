# Mitwirken an font_sharpener

**Sprachen:** [English](CONTRIBUTING.md) | [Русский](CONTRIBUTING.ru.md) | **Deutsch** (diese Seite)

Vielen Dank für Ihr Interesse an diesem Projekt! Dieses Dokument enthält Richtlinien für eine sichere Mitarbeit.

## Erste Schritte

1. **Forken Sie das Repository** auf GitHub
2. **Klonen Sie Ihren Fork** lokal:
   ```bash
   git clone git@github.com:IHRE_USERNAME/font_sharpener.git
   cd font_sharpener
   ```
3. **Erstellen Sie einen Feature-Branch:**
   ```bash
   git checkout -b feature/ihre-feature-name
   ```

## Entwicklungsumgebung

### Anforderungen

- Windows PowerShell 5.0 oder später
- Git 2.30+
- Optional: pre-commit framework

### Pre-commit Hooks

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files
```

## Sicherheitsrichtlinien

**WICHTIG:** Dieses Projekt ändert die Windows-Registry. Sicherheit hat oberste Priorität.

### ✅ Tun Sie:

- Testen Sie gründlich in einer sicheren Umgebung
- Dokumentieren Sie alle Registry-Änderungen
- Kommentieren Sie komplexe Operationen
- Überprüfen Sie Abwärtskompatibilität
- Folgen Sie PowerShell-Best Practices
- Behandeln Sie Fehler konsistent

### ❌ Tun Sie nicht:

- Commiten Sie keine Passwörter oder Tokens
- Hardcoden Sie keine API-Schlüssel
- Fügen Sie keine externen Abhängigkeiten ohne Review hinzu
- Modifizieren Sie .git/config mit eingebetteten Tokens
- Fügen Sie keine persönlichen Daten ein
- Überspringen Sie keine Fehlerbehandlung

## Code-Stil

### PowerShell

```powershell
# Verwenden Sie beschreibende Namen
$registryKeys = @( "DpiScalingVer", "Win8DpiScaling", "LogPixels", "FontSmoothing" )

# Einrückung: 4 Leerzeichen
function Backup-RegistryKeys {
    foreach ($key in $registryKeys) {
        # Code hier
    }
}

# Kommentieren Sie komplexe Logik
# Backup-Methode: Erstellen Sie mit Unterstrich suffixierte Werte
Set-ItemProperty -Path $regPath -Name "$($key)_" -Value $originalValue

Write-Host "Backup erstellt: $key -> $($key)_" -ForegroundColor Green
```

## Commit-Nachrichten

```
fix: prevent DPI scaling regression on Windows 10
docs: update troubleshooting section
test: verify backup/restore functionality
refactor: improve error handling
```

## Pull Request Prozess

1. Aktualisieren Sie die Dokumentation bei Bedarf
2. Testen Sie gründlich
3. Verifizieren Sie keine Secrets in Änderungen
4. Beschreiben Sie den PR klar:
   - Was hat sich geändert?
   - Warum?
   - Wie kann man es testen?
5. Verlinken Sie verwandte Issues

## Lizenz

Durch Ihre Mitarbeit stimmen Sie zu, dass Ihre Beiträge unter derselben Lizenz wie das Projekt lizenziert werden.
