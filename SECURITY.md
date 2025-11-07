# Security Policy for font_sharpener

## Reporting Security Vulnerabilities

If you discover a security vulnerability in this repository, please **do not** open a public issue. Instead:

1. Email security concerns to the repository maintainers
2. Provide a detailed description of the vulnerability
3. Include steps to reproduce (if applicable)
4. Allow 90 days for a fix before public disclosure

## Security Best Practices for Contributors

### Preventing Credential Leakage

This repository uses SSH authentication to prevent credential exposure in git configuration.

#### ✅ Recommended: SSH Authentication

```bash
# Set up SSH key (one-time setup)
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add public key to GitHub: https://github.com/settings/keys
cat ~/.ssh/id_ed25519.pub

# Clone using SSH
git clone git@github.com:nagual2/font_sharpener.git

# If already cloned with HTTPS, switch to SSH
git remote set-url origin git@github.com:nagual2/font_sharpener.git
```

#### ❌ NOT Recommended: HTTPS with Personal Access Tokens

Do NOT embed Personal Access Tokens in git URLs like:
```bash
# NEVER DO THIS
git clone https://username:TOKEN@github.com/user/repo.git
```

### Secret Scanning

Before committing, verify no secrets are included:

```bash
# Check staged changes for secrets
git diff --cached | grep -iE "password|token|api.?key|secret|credential"

# Or use gitleaks (if installed)
gitleaks detect --staged
```

### Pre-commit Hooks

To enable automatic secret scanning before commits:

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# (Optional) Run manually
pre-commit run --all-files
```

### Environment Variables

Store configuration and sensitive data in environment variables, not in code:

```bash
# Good: Use environment variables
$env:MY_API_KEY = "secret"
# In script: $apiKey = [System.Environment]::GetEnvironmentVariable("MY_API_KEY")

# Bad: Hardcode in script
$apiKey = "secret123"  # Never do this
```

### Code Review Checklist

Before creating a pull request, ensure:

- [ ] No passwords or tokens are included
- [ ] No API keys are hardcoded
- [ ] No private keys or certificates are committed
- [ ] No PII (emails, phone numbers) is exposed
- [ ] No internal URLs or IP addresses are leaked
- [ ] All external services use environment variables or secure methods
- [ ] Comments don't contain sensitive information

## GitHub Security Configuration

This repository has the following security settings:

1. **Branch Protection:** Main branch requires pull request reviews
2. **Automatic Dependency Updates:** Enabled via Dependabot
3. **Secret Scanning:** Recommended for all repositories
4. **Code Scanning:** Use GitHub Actions for SAST

## Audit Schedule

Security audits are recommended quarterly or after significant changes:

```bash
# Run security audit
gitleaks detect --verbose
ripgrep --type-add 'ps1:*.ps1' -i "password|token|secret" .
```

## Dependencies

This script has minimal dependencies (Windows PowerShell 5.0+) and does not import external packages, reducing attack surface.

### Monitoring

Check for dependency vulnerabilities:

- GitHub's built-in vulnerability scanning
- Manual reviews of any added dependencies
- Security advisories for PowerShell modules (if any are added)

## Compliance

This repository follows:

- GitHub Security Best Practices: https://docs.github.com/en/code-security
- CWE/SANS Top 25: Focus on A02:2021 Cryptographic Failures
- OWASP Top 10: Credential exposure prevention

## Additional Resources

- [GitHub Security Documentation](https://docs.github.com/en/security)
- [OWASP Credential Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Credential_Management_Cheat_Sheet.html)
- [CWE-798: Use of Hard-Coded Credentials](https://cwe.mitre.org/data/definitions/798.html)
- [GitHub Token Security](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token)

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2024-11-07 | Initial security policy created after audit |

---

Last Updated: 2024-11-07
