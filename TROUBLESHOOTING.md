# Troubleshooting

Quick reference for common issues and debugging techniques.

## Quick Diagnostics

```bash
task test           # Run all tests
task lint           # Run all linters
chezmoi verify      # Verify chezmoi state
chezmoi doctor      # Check chezmoi setup
```

## Bootstrap Script Issues

### Bootstrap Script Fails to Download

**Check connectivity:**

```bash
curl -I https://smyk.la                  # Should return 200 OK
ping github.com                          # Verify GitHub access
```

**Download and inspect script manually:**

```bash
curl -fsSL https://smyk.la > /tmp/bootstrap.sh
less /tmp/bootstrap.sh
bash /tmp/bootstrap.sh
```

### Age Key Retrieval Fails

**1Password CLI not authenticated:**

```bash
op signin                                # Sign in to 1Password
op document get dyhxf4wgavxqwt23wbsl5my2m > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt
```

**Manual key entry:**

If 1Password CLI fails, the script will prompt for manual key entry. Copy your age key (starts with `AGE-SECRET-KEY-`) and paste when prompted.

### Homebrew Installation Hangs

**Kill and restart:**

```bash
# Ctrl+C to cancel
# Run bootstrap again - it will detect existing Homebrew
curl -fsSL https://smyk.la | bash
```

### Repository Already Exists

The bootstrap script will detect existing repositories and offer to update them. If you want a fresh clone:

```bash
mv ~/Projects/github.com/smykla-labs/.dotfiles ~/Projects/github.com/smykla-labs/.dotfiles.backup
curl -fsSL https://smyk.la | bash
```

### Git Filter Configuration Fails

**Verify scripts exist:**

```bash
ls -la ~/Projects/github.com/smykla-labs/.dotfiles/.git/age-*.sh
```

**Reconfigure manually:**

```bash
cd ~/Projects/github.com/smykla-labs/.dotfiles
git config filter.age.clean "$PWD/.git/age-clean.sh"
git config filter.age.smudge "$PWD/.git/age-smudge.sh"
```

### Task Install Fails

**Check Task availability:**

```bash
which task                               # Should show path
brew install go-task                     # Install if missing
```

**Run manually:**

```bash
cd ~/Projects/github.com/smykla-labs/.dotfiles
task install
```

### Chezmoi Init Hangs

If chezmoi init hangs waiting for input:

```bash
# Ctrl+C to cancel
# Run with environment variables
BOOTSTRAP_EMAIL=user@example.com BOOTSTRAP_NAME="Full Name" \
  curl -fsSL https://smyk.la | bash -s -- --yes
```

### Bootstrap Completes but Shell Not Changed

**Restart terminal:**

```bash
# Or manually switch to Fish:
exec $(which fish)
```

**Verify Fish is default shell:**

```bash
echo $SHELL                              # Should show Fish path
chsh -s $(which fish)                    # Set if not default
```

## Chezmoi Issues

### Files Not Syncing

**Check state:**

```bash
chezmoi diff                # See pending changes
chezmoi status              # Check modified files
```

**Apply changes:**

```bash
chezmoi apply --verbose     # Apply with detailed output
```

**Fix out-of-sync file:**

```bash
chezmoi forget ~/.config/problematic-file
chezmoi add ~/.config/problematic-file
```

### Encrypted Files Not Decrypting

**Check age key:**

```bash
ls -la ~/.config/chezmoi/key.txt        # Should exist with 600 perms
age --decrypt --identity ~/.config/chezmoi/key.txt < chezmoi/encrypted_test.age
```

**Re-add encrypted file:**

```bash
chezmoi forget ~/.config/problematic-file
chezmoi add --encrypt ~/.config/problematic-file
```

## Git Filter Issues

### Files Not Encrypting/Decrypting

**Check git filters:**

```bash
git config filter.age.clean     # Should show encryption command
git config filter.age.smudge    # Should show decryption command
```

**Re-configure filters:**

```bash
git config filter.age.clean "~/.git/age-clean.sh"
git config filter.age.smudge "age --decrypt --identity ~/.config/chezmoi/key.txt 2>/dev/null || cat"
```

**Force re-encryption:**

```bash
git rm --cached path/to/file
git add path/to/file
```

## Test Failures

### ShellSpec Tests Failing

**Run specific test:**

```bash
shellspec spec/specific_test_spec.sh
```

**Verbose output:**

```bash
shellspec --format documentation spec/
```

### Fish Syntax Errors

**Check fish config:**

```bash
fish --no-execute ~/.config/fish/config.fish
```

## Tool Issues

### mise Tools Not Available

**Check mise:**

```bash
mise doctor                 # Diagnose mise issues
mise list                   # Show installed tools
mise install                # Install missing tools
```

### Task Command Not Found

**Install dependencies:**

```bash
brew install go-task
mise install
```

## CI/CD Issues

### GitHub Actions Failing

**Check workflow locally:**

```bash
actionlint .github/workflows/test.yaml
```

**Test age decryption:**

```bash
age --decrypt --identity ~/.config/age/ci-key.txt < CLAUDE.md
```

## System Architecture

The dotfiles system uses:

- **chezmoi**: Manages dotfiles, applies templates, encrypts secrets
- **age**: Encrypts files (both chezmoi-managed and git-filter managed)
- **Task**: Runs tests and linters
- **mise**: Manages tool versions

### Two Encryption Systems

1. **Chezmoi encryption** (`encrypted_*.age` in source):
   - Managed by chezmoi
   - Use `chezmoi add --encrypt` to add
   - Decrypt on `chezmoi apply`

2. **Git filter encryption** (via `.gitattributes`):
   - Transparent encryption on commit
   - Files: `CLAUDE.md`, `secrets/**`, `todos/**`
   - Configured in `.git/age-clean.sh` and `.git/age-smudge.sh`

## Getting Help

See full documentation:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development workflow
- [TESTING.md](TESTING.md) - Testing approach
- [README.md](README.md) - Quick start and overview
