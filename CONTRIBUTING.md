# Contributing to font_sharpener

Thank you for your interest in contributing to font_sharpener! This document provides guidelines for contributing safely and securely.

## Getting Started

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:
   ```bash
   git clone git@github.com:YOUR_USERNAME/font_sharpener.git
   cd font_sharpener
   ```
3. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

## Development Environment Setup

### Requirements

- Windows PowerShell 5.0 or later (for script development)
- Git 2.30+ (for security features)
- Optional: pre-commit framework for local checks

### Optional: Set up Pre-commit Hooks

Pre-commit hooks automatically check for common issues before commits:

```bash
# Install pre-commit framework
pip install pre-commit

# Install hooks
cd /path/to/font_sharpener
pre-commit install

# (Optional) Test hooks on all files
pre-commit run --all-files
```

## Security Guidelines

**CRITICAL:** This project handles Windows registry modifications. Security is paramount.

### ✅ DO:

- Test changes thoroughly in a safe environment
- Document all registry changes clearly
- Include comments for complex registry operations
- Verify backward compatibility
- Follow PowerShell best practices
- Use consistent error handling
- Test with least-privilege accounts (if possible)

### ❌ DON'T:

- Commit passwords, tokens, or secrets
- Hardcode API keys or credentials
- Add external dependencies without review
- Modify .git/config with embedded tokens
- Include personal information (emails, usernames, paths)
- Make unnecessary registry changes
- Skip error handling
- Use deprecated PowerShell features

### Credential Security

**Never commit secrets.** This includes:

- GitHub Personal Access Tokens
- SSH private keys
- AWS/Azure credentials
- Database passwords
- API keys

**If you accidentally commit a secret:**

1. **Immediately notify maintainers**
2. The token/credential must be revoked on the service (GitHub, AWS, etc.)
3. Use `git history-rewrite` or `BFG Repo-Cleaner` to remove from history

### Before Submitting a PR

```bash
# 1. Check for secrets
git diff origin/main | grep -iE "password|token|api.?key|secret|credential"

# 2. Run security checks
gitleaks detect --staged

# 3. Verify no commits contain secrets
gitleaks detect

# 4. Run pre-commit hooks (if installed)
pre-commit run --all-files
```

## Code Style

### PowerShell

Follow these guidelines for PowerShell code:

```powershell
# Use descriptive names
$registryKeys = @( "DpiScalingVer", "Win8DpiScaling", "LogPixels", "FontSmoothing" )

# Use proper indentation (4 spaces, not tabs)
function Backup-RegistryKeys {
    foreach ($key in $registryKeys) {
        # Code here
    }
}

# Comment complex logic
# Backup method: Create underscore-suffixed registry values
Set-ItemProperty -Path $regPath -Name "$($key)_" -Value $originalValue

# Use Write-Host for user messages (with color when appropriate)
Write-Host "Backup created: $key -> $($key)_" -ForegroundColor Green

# Use Write-Error for errors
Write-Error "Failed to backup registry key: $key"
```

### Comments

- Keep comments clear and concise
- Explain "why" not "what" (code shows what it does)
- Update comments when code changes
- Never include sensitive information in comments

### Documentation

- Update README.md if behavior changes
- Document new parameters with examples
- Include usage scenarios
- Test examples before committing

## Commit Messages

Use clear, descriptive commit messages:

```
# Format: <type>: <description>
# Examples:
fix: prevent DPI scaling regression on Windows 10
docs: update troubleshooting section
test: verify backup/restore functionality
refactor: improve error handling in registry operations
```

**Do not include:**
- Sensitive information
- Token/API key references
- Personal details
- Profanity

## Pull Request Process

1. **Update documentation** if necessary
2. **Test thoroughly** on Windows (if possible)
3. **Verify no secrets** in changes
4. **Write clear PR description**:
   - What changed?
   - Why did you change it?
   - How can reviewers test this?
5. **Link related issues** if applicable
6. **Request review** from maintainers

### PR Template

```markdown
## Description
Brief description of changes

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Registry value adjustment

## Testing
- [ ] Tested on Windows 10
- [ ] Tested on Windows 11
- [ ] Verified backup created
- [ ] Verified restore works

## Checklist
- [ ] No secrets in changes
- [ ] Code follows style guidelines
- [ ] Documentation updated
- [ ] Tests pass locally
- [ ] No breaking changes
```

## Testing Registry Changes

**IMPORTANT:** Always test in a controlled environment!

### Safe Testing:

1. **Create a restore point:**
   ```powershell
   wmic.exe /namespace:\\.\root\cimv2 logicaldisk where name="C:" get freespace
   # Ensure at least 5GB free space
   
   # Create restore point
   Checkpoint-Computer -Description "Before testing font_sharpener"
   ```

2. **Test in a virtual machine** (recommended)

3. **Verify changes work:**
   ```powershell
   # After running script, verify values
   $regPath = 'HKCU:\Control Panel\Desktop'
   Get-ItemProperty -Path $regPath -Name "DpiScalingVer", "Win8DpiScaling", "LogPixels", "FontSmoothing"
   ```

4. **Test restore procedure:**
   ```powershell
   # Verify backup values exist
   Get-ItemProperty -Path $regPath -Name "DpiScalingVer_", "Win8DpiScaling_", "LogPixels_", "FontSmoothing_"
   
   # Run restore snippet from README
   ```

## Issue Reporting

If you find a security vulnerability, please **do not** open a public issue. See [SECURITY.md](SECURITY.md) for reporting procedures.

For other issues:

1. **Check existing issues** to avoid duplicates
2. **Be specific** about the problem
3. **Include steps to reproduce**
4. **Provide environment details** (Windows version, PowerShell version)
5. **Share relevant error messages**

### Issue Template

```markdown
## Description
Clear description of the issue

## Environment
- Windows Version: [10/11]
- PowerShell Version: [5.0/7.x]
- font_sharpener Version: [version or date]

## Steps to Reproduce
1. ...
2. ...
3. ...

## Expected Behavior
What should happen

## Actual Behavior
What actually happens

## Error Messages
If applicable, paste error messages or logs
```

## Code Review

All pull requests require review before merging. Reviewers will check for:

- ✅ Security issues
- ✅ Code quality
- ✅ Registry safety
- ✅ Backward compatibility
- ✅ Documentation accuracy
- ✅ No credential leakage

## Questions?

- Review the [README.md](README.md) for usage information
- Check [SECURITY.md](SECURITY.md) for security guidelines
- Open an issue for general questions

## License

By contributing, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to font_sharpener! Your efforts help make this project better and more secure.

Last Updated: 2024-11-07
