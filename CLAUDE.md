# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Personal macOS dotfiles managed with:

- **[Nix](https://nixos.org/)**: Package management and system configuration
- **[Home Manager](https://github.com/nix-community/home-manager)**: User environment management
- **[nix-darwin](https://github.com/LnL7/nix-darwin)**: macOS system configuration
- **[sops-nix](https://github.com/Mic92/sops-nix)**: Secrets management
- **[age](https://age-encryption.org/)**: File encryption
- **[Taskfile](https://taskfile.dev)**: Task automation
- **[mise](https://mise.jdx.dev/)**: Tool version management

## Repository Structure

```text
.dotfiles/
├── nix/                       # Nix configuration
│   ├── flake.nix              # Flake entry point
│   ├── flake.lock             # Locked dependencies
│   ├── modules/               # Nix modules
│   │   ├── darwin/            # nix-darwin modules (system-level)
│   │   └── home/              # home-manager modules (user-level)
│   └── secrets/               # sops-nix encrypted secrets
│       ├── .sops.yaml         # sops configuration
│       └── secrets.yaml       # Encrypted secrets
├── .github/workflows/         # CI/CD
│   ├── codeql.yaml            # CodeQL security analysis
│   ├── scorecards.yaml        # OpenSSF Scorecard
│   └── test.yaml              # Test pipeline (Ubuntu + macOS)
├── hooks/                     # Git hooks (NOT Claude Code hooks)
│   ├── pre-commit             # Runs 'task lint'
│   └── pre-push               # Runs 'task test'
├── tmp/                       # Temporary files (NEVER commit)
├── Taskfile.yaml              # Task automation (test, lint, hooks, etc.)
├── Brewfile                   # Homebrew packages (legacy, migrating to nix)
├── SECURITY.md                # Security policy and vulnerability reporting
├── CLAUDE.md                  # This file
├── secrets/                   # Encrypted secrets (via git filter)
└── todos/                     # Personal todos (encrypted via git filter)
```

## Nix

### Rebuild Commands

- **Home Manager** (user config):

  ```bash
  home-manager switch --flake $DOTFILES_PATH/nix#home-bart
  ```

- **Darwin** (system config, requires `sudo`):

  ```bash
  sudo darwin-rebuild switch --flake $DOTFILES_PATH/nix#bartsmykla
  ```

### Key Concepts

- **Flake**: Entry point at `nix/flake.nix`, defines inputs and outputs
- **Home Manager modules**: User-level config in `nix/modules/home/`
- **Darwin modules**: System-level config in `nix/modules/darwin/`
- **Secrets**: Managed via sops-nix in `nix/secrets/`

### Editing Secrets

```bash
SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml
```

## Age Encryption

Encryption using age for repository files:

- **Key location**: `~/.config/age/key.txt` (never commit)
- **Repository files**: Encrypted via git clean/smudge filters

Encrypted file patterns (`.gitattributes`):

- `secrets/**`
- `todos/**`
- `**/**.secret.*` files

**Important**: When committing encrypted files, never leak actual content in commit messages.

## Development Workflow

### Making Changes

1. Create feature branch: `git checkout -b <type>/<description>`
2. Edit nix modules in `nix/modules/`
3. Test changes: `task test && task lint`
4. Apply changes:
   - User config: `home-manager switch --flake $DOTFILES_PATH/nix#home-bart`
   - System config: `sudo darwin-rebuild switch --flake $DOTFILES_PATH/nix#bartsmykla`
5. Commit changes: `git commit -sS -m "type(scope): description"`
6. Push to remote: `git push upstream <branch-name>`
7. Create pull request and self-review before merging

### Taskfile Commands

Use `task` for common operations:

```bash
task test          # Run all tests
task lint          # Run all linters (shellcheck, markdownlint, etc.)
task check         # Alias for lint

task test:fish     # Test Fish config syntax
task lint:shell    # Shellcheck validation
task lint:markdown # Markdown linting
task lint:taskfile # Validate Taskfile.yaml

task --list        # Show all available tasks
```

### Testing

All changes must pass automated tests:

- **Fish scripts**: Syntax validation (`fish -n`)
- **Shell scripts**: Shellcheck linting
- **Markdown**: Markdownlint validation
- **Taskfile**: JSON schema validation

CI runs on every push (Ubuntu 24.04 and macOS 15).

See [TESTING.md](TESTING.md) for comprehensive documentation.

## Shell Environment

**Shell**: Fish shell (version 3.x)

**Key environment variables**:

- `$PROJECTS_PATH` - `$HOME/Projects/github.com`
- `$MY_PROJECTS_PATH` - `$PROJECTS_PATH/bartsmykla`
- `$DOTFILES_PATH` - `$PROJECTS_PATH/smykla-labs/.dotfiles`
- `$SECRETS_PATH` - `$DOTFILES_PATH/secrets`

## Tool Management

Tools managed via nix (see `nix/modules/home/` for package lists).

Additional tools via mise for development:

```bash
mise use <tool>@<version>    # Pin specific version
mise install                 # Install tools
```

## Python Development Environment

Dynamic Python environments with **direnv** per-project activation. Packages are read from `requirements.txt` or `pyproject.toml`. Python version can be specified via **mise** config files.

### Quick Start

**Automatic**: Just `cd` into any directory with `requirements.txt` or `pyproject.toml`. Fish shell automatically:

1. Creates `.envrc` with `use_python_env`
2. Adds `.envrc` to `.git/info/exclude` (including all worktrees)
3. Runs `direnv allow`

**Manual**: If auto-detection doesn't trigger, create `.envrc` yourself:

```bash
echo 'use_python_env' > .envrc        # With activation message
echo 'use_python_env --quiet' > .envrc # Silent mode
direnv allow
```

The environment auto-loads when you `cd` into the project, reading packages from:

1. `pyproject.toml` (via `uv sync --all-groups`) - handles `[project].dependencies`, `[project.optional-dependencies]`, and `[dependency-groups]`
2. `requirements.txt` (via `uv pip install -r`) - fallback if no pyproject.toml

If neither file exists, a bare Python environment (stdlib only) is provided.

### Files

**Project files**:

```text
your-project/
├── .envrc              # Auto-created, contains: use_python_env
├── .mise.toml          # mise config: python = "3.11" (or any mise config file)
├── requirements.txt    # pip format: requests>=2.28.0
└── pyproject.toml      # [project.dependencies], [project.optional-dependencies], [dependency-groups]
```

**Supported mise config files** (checked in precedence order):

1. `.mise.local.toml` - Local overrides (gitignored)
2. `.mise.toml` - Project config (recommended)
3. `mise.local.toml` - Local overrides without dot prefix
4. `mise.toml` - Project config without dot prefix
5. `.config/mise.toml` - XDG-style config
6. `.config/mise/config.toml` - XDG-style nested config
7. `.tool-versions` - Legacy asdf format

**Central infrastructure** (`$DOTFILES_PATH/nix/python-env/`):

- `shell.nix` - Parameterized nix shell that provides Python interpreter
- `nixpkgs-python-versions.json` - List of Python versions available in nixpkgs

### How It Works

1. `use_python_env` reads Python version from mise config files (see supported files above)
2. Mode selection based on Python version:
   - **Nix mode** (3.10-3.13): Uses nixpkgs Python interpreter
   - **mise mode** (3.14+): Uses mise to install Python
3. Creates `.venv` using `uv venv`
4. Installs packages via uv:
   - `pyproject.toml`: `uv sync --all-groups` (handles all dependency types)
   - `requirements.txt`: `uv pip install -r requirements.txt`
5. nix-direnv caches environments for fast subsequent loads

### IDE Integration

A `.venv` directory is automatically created. IDEs (VS Code, PyCharm, etc.) auto-detect `.venv/bin/python`.

**Environment variables set:**

- `PYTHONPATH` - Points to site-packages
- `VIRTUAL_ENV` - Points to `.venv` directory

**IDE interpreter path:** `.venv/bin/python`

No configuration needed - IDEs find it automatically in both modes.

### Why This Approach

- **Per-project packages**: Each project gets exactly the dependencies it declares
- **Standard formats**: Uses familiar `requirements.txt` and `pyproject.toml`
- **Opt-in**: Projects choose to activate Python environment
- **Performance**: nix-direnv caches environments (~750ms faster after first load)
- **No version conflicts**: Each project is isolated
- **Workaround**: Fixes [nixpkgs#61144](https://github.com/NixOS/nixpkgs/issues/61144) where `python.withPackages` doesn't set PYTHONPATH

### Python Version Selection

Specify Python version per-project using mise:

```toml
# .mise.toml
[tools]
python = "3.11"    # Uses nixpkgs python311
# python = "3.14"  # Falls back to mise + uv (not in nixpkgs)
```

Or using `.tool-versions`:

```text
python 3.12
```

**Mode selection**:

| Version   | Python Source | Package Source |
|-----------|---------------|----------------|
| 3.10-3.13 | nixpkgs       | PyPI (via uv)  |
| 3.14+     | mise          | PyPI (via uv)  |

**Activation messages**:

```text
🐍 Python 3.11.14 (nix) + uv
   Packages: 6 from requirements.txt
   IDE path: .venv/bin/python

🐍 Python 3.14.2 (mise) + uv
   Packages: 10 from pyproject.toml
   IDE path: .venv/bin/python
```

### Package Version Management

All packages are installed from PyPI via uv, which respects version specifiers in `requirements.txt` and `pyproject.toml`.

**Example**:

```text
# requirements.txt
requests>=2.28.0  # Will install latest compatible version
```

### Troubleshooting

**Package not found**: Check the package name on PyPI - uv installs directly from there

**Old environment cached**: Remove `.direnv/` and `.venv`, then re-allow:

```bash
rm -rf .direnv .venv && direnv allow
```

**Check generated nix file (nix mode)**:

```bash
cat .direnv/python-shell.nix
```

**mise+uv mode not installing packages**: Ensure `uv` is available and check the venv:

```bash
which uv
ls -la .venv/bin/
```

**Wrong Python version**: Check mise config is being read:

```bash
mise which python           # Check which Python mise resolves
mise config --local         # Show local mise config
```

### Resources

- [PYTHON-ENV.md](PYTHON-ENV.md) - Architecture and implementation details
- [Fixing Python Import Resolution in Nix with Direnv](https://cyberchris.xyz/posts/nix-python-pyright/)
- [nix-direnv Performance](https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/)
- [Simple Python devshells](https://sgt.hootr.club/blog/python-nix-shells/)

## Fish Functions

Custom Fish functions (managed via nix home-manager):

- **`git_clone_to_projects`** - Clone repos to `$PROJECTS_PATH/{org}/{repo}`
- **`git-checkout-default-fetch-fast-forward`** - Checkout, fetch, and fast-forward default branch
- **`git-push-upstream-first-force-with-lease`** - Push to upstream with `--force-with-lease`
- **`klg`** - Kubernetes pod logs
- **`kls`** - List Kubernetes resources
- **`mkd`** - Create directory and cd into it
- **`git_clean_branches`** - Clean merged local branches without remote counterpart

All functions should have `--description` or `-d` flag.

## Integrations

- **fzf**: Fuzzy finder for directories, git log/status, processes, variables
- **Atuin**: Shell history sync and search
- **direnv**: Auto-load environment from `.envrc`
- **starship**: Cross-shell prompt
- **jump**: Directory navigation
- **1Password**: SSH agent (`$SSH_AUTH_SOCK`)

## Plugin Management

**Vim plugins** (Vundle):

- **Config**: Managed via nix home-manager
- **Plugins**: Installed via `vim +PluginInstall +qall`
- **Location**: `~/.vim/bundle/`

**Tmux plugins** (TPM):

- **Config**: Managed via nix home-manager
- **Plugins**: Installed via `<prefix> + I` inside tmux session
- **Location**: `~/.tmux/plugins/`

**Claude Code plugins**:

- **Config**: Managed via sops-nix secrets
- **Marketplaces**: Managed by Claude Code, auto-synced
- **Location**: `~/.claude/plugins/marketplaces/`

## Claude Code Hooks

Automated validation using dispatcher pattern: `~/.claude/hooks/dispatcher.sh` routes PreToolUse/PostToolUse events to specialized validators.

### Locations

- **Deployed**: `~/.claude/hooks/` (runtime location)
- **Logs**: `~/.claude/hooks/dispatcher.log`

### Available Validators

**Git Operations (PreToolUse):**

- `validate-git-add.sh` - Blocks `tmp/` files from staging
- `validate-commit.sh` - Conventional commits, 50/72 rule, empty line before lists, `-sS` flags
- `validate-git-push.sh` - Project-specific push rules
- `validate-branch-name.sh` - Branch naming conventions
- `validate-pr.sh` - PR creation validation

**File Operations (PostToolUse):**

- `validate-shellscript.sh` - Shellcheck on `*.sh`, `*.bash`
- `validate-markdown.sh` - Markdown formatting, empty lines before lists

### Debugging

```bash
export CLAUDE_HOOKS_DEBUG=true    # Enable logging
export CLAUDE_HOOKS_TRACE=true    # Verbose trace
tail -f ~/.claude/hooks/dispatcher.log
```

## Hammerspoon Debugging & IPC

Config: `nix/modules/home/hammerspoon/init.lua` → `~/.hammerspoon/init.lua` (symlinked by home-manager)

**Console**: Hammerspoon menubar → "Console..." (view errors/logs)

### IPC Command Best Practices

**CRITICAL**: Always use `-q` (quiet mode) and `-t` timeout to prevent hanging:

```bash
hs -q -t 2 -c "return 'value'"           # CORRECT: return + quiet + timeout
hs -c "print('value')"                   # WRONG: hangs, buffers in console
```

**Why commands hang**:

- `print()` redirects to Hammerspoon console, can buffer/block IPC
- Rapid command succession invalidates message port ([#2974](https://github.com/Hammerspoon/hammerspoon/issues/2974))
- Missing timeout causes indefinite wait for Hammerspoon idle state
- `hs.reload()` invalidates IPC port (exit code 69 is normal)

**Flags**:

- `-q`: Quiet mode, only outputs final result (prevents console buffer issues)
- `-t SEC`: Timeout in seconds (default can hang indefinitely)
- `-P`: Mirror print() to Hammerspoon console (debugging only)

### Status Checks

```bash
hs -q -t 2 -c "return tostring(config ~= nil)"                    # Config loaded?
hs -q -t 2 -c "return type(updateGhosttyFontSize)"               # Function exists?
hs -q -t 2 -c "return tostring(config.ghosttyFontSizeWithMonitor)" # Check values
hs -c "hs.reload()" 2>&1                                          # Reload (ignore port errors)
```

### Debug Mode

Enable verbose logging, startup alerts, display detection:

```bash
hs -q -t 2 -c "toggleDebugMode(); return 'toggled'"  # Toggle via IPC
# OR: Cmd+Alt+Ctrl+H → Enable Debug Mode → Save → Reload
# OR: DEBUG_MODE=true hs
```

### View Logs

```bash
hs -q -t 5 -c "return hs.console.getConsole()"  # Console output (increase timeout)
hs -q -t 2 -c "log.printHistory()"              # Logger history
```

### Troubleshooting

**"config is nil"** → init.lua failed to load:

1. Check Console (menubar → Console...) for Lua errors
2. `ls -la ~/.hammerspoon/init.lua` (verify symlink)
3. `home-manager switch --flake $DOTFILES_PATH/nix#home-bart` (rebuild)
4. `hs -c "hs.reload()"`

**"message port invalid"** → Normal during reload, ignore

**Docs**: [hs.ipc](https://www.hammerspoon.org/docs/hs.ipc.html) · [hs.logger](https://www.hammerspoon.org/docs/hs.logger.html) · [hs.console](https://www.hammerspoon.org/docs/hs.console.html) · [CLI Usage](https://stackoverflow.com/questions/69711165/how-to-use-the-hammerspoon-cli)

## Git Workflow

- **Branch-based development**: All changes must go through pull requests
  - Create feature branches for all work: `git checkout -b <type>/<description>`
  - Branch naming: descriptive, kebab-case (e.g., `feat/add-new-function`, `fix/shell-syntax`)
  - Push to remote and create PR for review
  - Self-review PRs before merging to ensure quality
- **Signing**: All commits must use `-sS` flags (sign-off + GPG)
- **Commit format**: Conventional commits (`type(scope): description`)
- **Pushing**: Wait for explicit instruction before pushing to remote
- **Remotes**: `upstream` (main repo), `origin` (fork)
- **Merging**: Use GitHub UI to merge PRs after CI passes and self-review completes

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed commit guidelines.

### Git Hooks

Automated quality checks via git hooks:

- **Installation**: Run `task hooks:install` to set up hooks
- **pre-commit**: Runs `task lint` before each commit
- **pre-push**: Runs `task test` before each push
- **Bypass**: Use `--no-verify` flag when needed
- **Location**: Source files in `hooks/`, installed to `.git/hooks/`

Hooks ensure code quality and prevent broken code from being committed or pushed.

## Writing Shell Scripts

- **Linting**: Must pass `shellcheck` with no warnings
  - Claude Code hooks automatically run shellcheck on write
  - All hook scripts are validated before deployment
- **Style**: Use long flags for readability (`--force` not `-f`)
- **Fish functions**: Add `--description` flag
- **Secrets**: Files matching `**.secret.*` are encrypted

## Homebrew Packages

Core tools (from `Brewfile`, migrating to nix):

- **Shell**: fish, bash, starship, atuin
- **Dev**: docker, kubernetes-cli, k3d, k9s, helm, terraform
- **Git**: gh
- **Utils**: fzf, fd, eza, bat, jq, yq, direnv, jump
- **Cloud**: awscli, gcloud, saml2aws
- **Editors**: vim, tmux

## Documentation

- **[README.md](README.md)**: Project overview and quick start
- **[PYTHON-ENV.md](PYTHON-ENV.md)**: Python environment architecture and internals
- **[TESTING.md](TESTING.md)**: Testing approach and commands
- **[CONTRIBUTING.md](CONTRIBUTING.md)**: Contribution guidelines
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)**: Debugging and troubleshooting guide
- **[SECURITY.md](SECURITY.md)**: Security policy and vulnerability reporting

## Common Tasks

Refer to documentation for detailed workflows:

- **Development workflow**: See [CONTRIBUTING.md](CONTRIBUTING.md#development-workflow)
- **Testing**: See [TESTING.md](TESTING.md)
- **Troubleshooting**: See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

## Security Notes

- **Age key**: `~/.config/age/key.txt` is private, never commit
- **Encrypted files**: Never expose actual content in commit messages
- **Secrets**: Managed via sops-nix for nix configs, git filters for repo files
- **Git filters**: Clean/smudge filters handle transparent encryption
