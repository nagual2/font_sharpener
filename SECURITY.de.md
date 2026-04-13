# Sicherheitsrichtlinie für font_sharpener

**Sprachen:** [English](SECURITY.md) | [Русский](SECURITY.ru.md) | **Deutsch** (diese Seite)

## Melden von Sicherheitslücken

Wenn Sie eine Sicherheitslücke entdecken, öffnen Sie bitte **kein öffentliches Issue**. Stattdessen:

1. Senden Sie eine E-Mail an die Maintainer
2. Beschreiben Sie die Sicherheitslücke detailliert
3. Fügen Sie Reproduktionsschritte hinzu (falls zutreffend)
4. Erlauben Sie 90 Tage für eine Korrektur vor der öffentlichen Offenlegung

## Best Practices für Mitwirkende

### Verhinderung von Credentials-Lecks

Dieses Repository verwendet SSH-Authentifizierung.

#### ✅ Empfohlen: SSH

```bash
ssh-keygen -t ed25519 -C "your_email@example.com"
cat ~/.ssh/id_ed25519.pub
git clone git@github.com:nagual2/font_sharpener.git
```

#### ❌ Nicht empfohlen: HTTPS mit Tokens

Betten Sie niemals Token in URLs ein:
```bash
# MACHEN SIE DIES NIE
git clone https://username:TOKEN@github.com/user/repo.git
```

### Secret-Scanning

```bash
git diff --cached | grep -iE "password|token|api.?key|secret|credential"
gitleaks detect --staged
```

### Code-Review-Checkliste

- [ ] Keine Passwörter oder Tokens
- [ ] Keine API-Keys im Code
- [ ] Keine privaten Schlüssel
- [ ] Keine persönlichen Daten
- [ ] Kommentare enthalten keine sensiblen Informationen

## GitHub-Sicherheitseinstellungen

- **Branch-Protection:** Main erfordert PR-Reviews
- **Abhängigkeitsupdates:** Dependabot aktiviert
- **Secret-Scanning:** Empfohlen

## Abhängigkeiten

Das Skript hat minimale Abhängigkeiten (PowerShell 5.0+) und importiert keine externen Pakete.

## Compliance

- GitHub Security Best Practices
- CWE/SANS Top 25
- OWASP Top 10

## Versionshistorie

| Version | Datum | Änderungen |
|---------|-------|------------|
| 1.0 | 2024-11-07 | Erste Sicherheitsrichtlinie |

---

Zuletzt aktualisiert: 2024-11-07
