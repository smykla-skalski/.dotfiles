# Security Policy

## Supported Versions

This repository contains personal dotfiles that are actively maintained. Security updates are applied to the latest version on the `main` branch.

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this dotfiles repository, please report it privately.

### What Constitutes a Security Issue

For this dotfiles repository, security issues include:

- **Exposed secrets or credentials**: Unencrypted sensitive data in the repository
- **Encryption vulnerabilities**: Issues with age encryption implementation or key management
- **Command injection**: Vulnerabilities in shell scripts or functions
- **Privilege escalation**: Scripts that could be exploited for unauthorized access
- **Dependency vulnerabilities**: Security issues in tools managed via mise or Homebrew

### How to Report

**Please do not** open a public issue for security vulnerabilities.

Instead, report security issues via:

1. **GitHub Security Advisories**: Use the [Security tab](https://github.com/smykla-labs/.dotfiles/security/advisories/new) to create a private security advisory
2. **Email**: Contact the repository owner directly via GitHub

### Response Timeline

- **Initial response**: Within 48 hours
- **Status update**: Within 7 days
- **Fix timeline**: Depends on severity and complexity

### Security Best Practices

This repository follows these security practices:

- **Encryption**: Sensitive files encrypted using age (replacing git-crypt)
- **Linting**: Automated shellcheck, markdownlint, and other linters via CI
- **Testing**: Automated tests for all shell scripts and configurations
- **Tool management**: Versioned tools via mise for reproducibility
- **Code review**: Changes validated through automated testing (CI/CD)

## Security Features

### Age Encryption

- Private key stored at `~/.config/chezmoi/key.txt` (never committed)
- Encrypted files: `secrets/**`, `todos/**`, `CLAUDE.md`, `**/**.secret.*`
- Transparent encryption via git clean/smudge filters

### Automated Security Checks

CI pipeline includes:

- Shell script validation (shellcheck)
- Markdown linting (markdownlint)
- Syntax validation for Fish shell configs
- Taskfile schema validation

## Disclosure Policy

After a vulnerability is fixed:

1. A security advisory will be published on GitHub
2. Affected users will be notified if applicable
3. Credit will be given to the reporter (unless they prefer to remain anonymous)
