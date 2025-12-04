# Troubleshooting

Quick reference for common issues and debugging techniques.

## Quick Diagnostics

```bash
task test           # Run all tests
task lint           # Run all linters
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
op document get dyhxf4wgavxqwt23wbsl5my2m > ~/.config/age/key.txt
chmod 600 ~/.config/age/key.txt
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

## Nix Issues

### Home Manager Build Fails

**Check configuration:**

```bash
home-manager switch --flake $DOTFILES_PATH/nix#home-bart --show-trace
```

**Rebuild with debugging:**

```bash
nix build --show-trace $DOTFILES_PATH/nix#homeConfigurations.home-bart.activationPackage
```

### Configuration Not Applied

**Force rebuild:**

```bash
home-manager switch --flake $DOTFILES_PATH/nix#home-bart --impure
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
git config filter.age.smudge "age --decrypt --identity ~/.config/age/key.txt 2>/dev/null || cat"
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

- **Nix/Home Manager**: Declaratively manages dotfiles and system configuration
- **sops-nix**: Manages secrets in `nix/secrets/secrets.yaml`
- **age**: Encrypts files (both sops-nix secrets and git-filter managed files)
- **Task**: Runs tests and linters
- **mise**: Manages tool versions

### Two Encryption Systems

1. **sops-nix secrets** (`nix/secrets/secrets.yaml`):
   - Managed via sops with age encryption
   - Edit: `SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml`
   - Deployed by Home Manager

2. **Git filter encryption** (via `.gitattributes`):
   - Transparent encryption on commit
   - Files: `CLAUDE.md`, `secrets/**`, `todos/**`
   - Configured in `.git/age-clean.sh` and `.git/age-smudge.sh`

## Getting Help

See full documentation:

- [CONTRIBUTING.md](CONTRIBUTING.md) - Development workflow
- [TESTING.md](TESTING.md) - Testing approach
- [README.md](README.md) - Quick start and overview
