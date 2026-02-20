# CLAUDE.md

## Architecture

**System**: Nix-based macOS dotfiles with declarative configuration management

**Config flow**: `nix/flake.nix` → nix modules → system/user environments

- `nix/modules/darwin/` - System-level config (nix-darwin) → macOS system settings, requires `sudo`
- `nix/modules/home/` - User-level config (home-manager) → dotfiles, shell, tools

**Key patterns**:

- Encryption: age + sops-nix (nix secrets), age + git filters (repo files)
- Secrets: `nix/secrets/secrets.yaml` (sops-encrypted) + `secrets/`, `todos/` (git-filtered)
- Python envs: direnv + nix/mise dual-mode, see `.claude/rules/python-env.md`
- Validation: Claude Code hooks at `~/.claude/hooks/dispatcher.sh` route PreToolUse/PostToolUse to validators

**Domain terms**:

- **flake** - Nix's reproducible build system entry point at `nix/flake.nix`
- **home-manager** - Declarative user environment manager
- **nix-darwin** - macOS system configuration layer
- **sops-nix** - Secrets OPerationS for Nix, encrypts `nix/secrets/secrets.yaml`
- **age** - Simple file encryption tool, key at `~/.config/age/key.txt`
- **mise** - Runtime version manager (replaces asdf), config at `.config/mise/config.toml`
- **direnv** - Auto-load project environments from `.envrc` files

## Commands

### Build/Apply

```bash
# Apply user config (dotfiles, shell, tools)
home-manager switch --flake $DOTFILES_PATH/nix#home-bart

# Apply system config (macOS settings, requires sudo)
sudo darwin-rebuild switch --flake $DOTFILES_PATH/nix#bartsmykla
```

### Test & Lint

```bash
task test          # Full test suite (syntax, shellspec)
task lint          # All linters (shellcheck, markdownlint, actionlint, taskfile schema)
task test:changed  # Smart tests (changed files only, used in pre-push hook)

# Single test/lint commands
task test:fish / task lint:shell / task lint:markdown / task lint:taskfile / task lint:actions / task test:shellspec
```

### Development

```bash
task hooks:install  # Install git hooks (pre-commit: lint, pre-push: test:changed)
task --list         # Show all tasks
```

### Secrets

```bash
# Edit nix secrets (sops-encrypted)
SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml

# Repository files in secrets/, todos/, **.secret.* are auto-encrypted via git filters
```

## Development Workflow

1. Create feature branch: `git checkout -b <type>/<description>` (kebab-case)
2. Edit nix modules in `nix/modules/`
3. Test: `task test && task lint`
4. Apply changes locally (see Commands → Build/Apply)
5. Commit: `git commit -sS -m "type(scope): description"` (conventional commits, sign-off + GPG)
6. Push: `git push upstream <branch-name>` (only when explicitly instructed)
7. Create PR and self-review before merging via GitHub UI

**Remotes**: `upstream` (main repo), `origin` (fork)
**Pre-commit hook**: Runs `task lint` (bypass with `--no-verify`)
**Pre-push hook**: Runs `task test:changed` (bypass with `--no-verify`)

See `CONTRIBUTING.md` for detailed commit guidelines.

## Shell Environment

**Shell**: Fish 3.x

**Key variables**:

- `$PROJECTS_PATH` = `$HOME/Projects/github.com`
- `$DOTFILES_PATH` = `$PROJECTS_PATH/smykla-skalski/.dotfiles`
- `$SECRETS_PATH` = `$DOTFILES_PATH/secrets`

**Custom Fish functions** (in `nix/modules/home/fish/functions/`): `git_clone_to_projects`, `git-checkout-default-fetch-fast-forward`, `git-push-upstream-first-force-with-lease`. All must include `--description` flag.

## Testing

**Frameworks**: ShellSpec (specs), shellcheck (shell), markdownlint (docs), actionlint (workflows)

**Organization**: Shell via `find . -name "*.sh" | xargs shellcheck`, Fish via `fish -n`, specs in `spec/`, CI on Ubuntu 24.04 + macOS 15

**Strategy**: Syntax validation + linting. ShellSpec for behavior tests when present.

## Claude Code Hooks

**Location**: `~/.claude/hooks/dispatcher.sh` (dispatcher pattern), **Logs**: `~/.claude/hooks/dispatcher.log`

**Validators**: PreToolUse (validate-git-add, validate-commit, validate-git-push, validate-branch-name, validate-pr), PostToolUse (validate-shellscript, validate-markdown)

**Debug**: `export CLAUDE_HOOKS_DEBUG=true && tail -f ~/.claude/hooks/dispatcher.log`

## Gotchas

- **tmp/ directory**: Temporary files only. Git hooks block staging `tmp/` - use specific file paths instead
- **Age key**: Store private key at `~/.config/age/key.txt` securely, excluded from git by default
- **Encrypted files**: Git-filtered files (secrets/, todos/, **.secret.*) auto-encrypt on commit, multi-recipient (personal + CI). Describe changes generically in commit messages (e.g., "update secrets")
- **Hammerspoon IPC**: Use `hs -q -t 2 -c "return 'value'"` format instead of `print()` - see `.claude/rules/hammerspoon.md` for details
- **Home Manager plugins**: Vim (Vundle) and Tmux (TPM) require manual install after nix config: `vim +PluginInstall +qall` and `<prefix> + I` in tmux
- **Python environments**: Auto-created per-project via direnv - see `.claude/rules/python-env.md`

## Writing Shell Scripts

- **Linting**: Must pass shellcheck with no warnings (Claude Code hooks auto-validate on write)
- **Style**: Long flags for readability (`--force`, not `-f`)
- **Fish functions**: Must include `--description` flag

## Resources

- **Modular rules**: `.claude/rules/python-env.md`, `.claude/rules/hammerspoon.md`
- **Documentation**: `CONTRIBUTING.md` (guidelines), `TESTING.md` (test details), `TROUBLESHOOTING.md` (debugging), `PYTHON-ENV.md` (architecture)
