# .dotfiles

Personal macOS dotfiles managed with [chezmoi](https://chezmoi.io), encrypted with [age](https://age-encryption.org/), and automated with [Task](https://taskfile.dev).

[![Test Dotfiles](https://github.com/smykla-labs/.dotfiles/actions/workflows/test.yaml/badge.svg)](https://github.com/smykla-labs/.dotfiles/actions/workflows/test.yaml)
[![CodeQL](https://github.com/smykla-labs/.dotfiles/actions/workflows/codeql.yaml/badge.svg)](https://github.com/smykla-labs/.dotfiles/actions/workflows/codeql.yaml)
[![Dependency Review](https://github.com/smykla-labs/.dotfiles/actions/workflows/dependency-review.yaml/badge.svg)](https://github.com/smykla-labs/.dotfiles/actions/workflows/dependency-review.yaml)
[![OpenSSF Scorecard](https://github.com/smykla-labs/.dotfiles/actions/workflows/scorecards.yaml/badge.svg)](https://github.com/smykla-labs/.dotfiles/actions/workflows/scorecards.yaml)

## Features

- **Dotfile Management**: chezmoi for cross-machine synchronization
- **Encryption**: age for secrets (multi-recipient: personal + CI keys)
- **Testing**: Automated syntax checks and linting via Task
- **Security**: CodeQL analysis, dependency scanning, OpenSSF Scorecard
- **Git Hooks**: Automated quality checks (lint on commit, test on push)
- **CI/CD**: GitHub Actions validates changes on Ubuntu & macOS
- **Tool Management**: mise for version-pinned development tools

## Quick Start

### Automated Installation (Recommended)

**One-line installation for fresh macOS machines:**

```bash
curl -fsSL https://smyk.la | bash
```

This will automatically:

- Install Homebrew and all dependencies
- Clone the repository to the correct location
- Set up age encryption
- Configure chezmoi and apply dotfiles
- Install Vim and Tmux plugins
- Set up git hooks

For non-interactive installation:

```bash
curl -fsSL https://smyk.la | bash -s -- --yes
```

With custom installation directory:

```bash
curl -fsSL https://smyk.la | bash -s -- --dir ~/dotfiles
```

With environment variables:

```bash
BOOTSTRAP_EMAIL=user@example.com BOOTSTRAP_NAME="Full Name" \
  curl -fsSL https://smyk.la | bash -s -- --yes
```

See [https://smyk.la](https://smyk.la) for more options. The default installation directory is `~/Projects/github.com/smykla-labs/.dotfiles`, but this can be customized using `--dir` flag or `BOOTSTRAP_DIR` environment variable.

### Manual Installation

If you prefer manual control over the installation process:

**Prerequisites:**

- macOS (tested on macOS 15)
- [Homebrew](https://brew.sh)

**Steps:**

```bash
# Clone repository
git clone https://github.com/smykla-labs/.dotfiles ~/Projects/github.com/smykla-labs/.dotfiles
cd ~/Projects/github.com/smykla-labs/.dotfiles

# Install Homebrew packages
brew bundle install --file=Brewfile

# Get age key from 1Password
mkdir -p ~/.config/chezmoi
op document get dyhxf4wgavxqwqt23wbsl5my2m > ~/.config/chezmoi/key.txt
chmod 600 ~/.config/chezmoi/key.txt

# Initialize chezmoi
chezmoi init --source "$PWD/chezmoi"

# Apply dotfiles
chezmoi apply

# Install vim plugins (Vundle)
vim +PluginInstall +qall

# Install tmux plugins (TPM) - run inside tmux session
# Press: <prefix> + I (default prefix is Ctrl-b)
```

### Development

```bash
# Install git hooks (recommended)
task hooks:install

# Run tests
task test

# Run linters
task lint

# List all tasks
task --list
```

Git hooks automate quality checks:

- **pre-commit**: Runs `task lint` before each commit
- **pre-push**: Runs `task test` before each push
- Skip with `--no-verify` flag if needed

## Repository Structure

```text
.dotfiles/
├── chezmoi/                   # Chezmoi source (dotfiles)
│   ├── .chezmoi.toml.tmpl     # Chezmoi config template
│   └── private_dot_config/    # Maps to ~/.config/
│       ├── fish/              # Fish shell
│       └── mise/              # Tool versions
├── .github/workflows/         # CI/CD workflows
├── hooks/                     # Git hooks (pre-commit, pre-push)
├── spec/                      # ShellSpec tests
├── Taskfile.yaml              # Task automation
└── Brewfile                   # Homebrew dependencies
```

## Core Tools

- **[chezmoi](https://chezmoi.io)**: Dotfile management
- **[age](https://age-encryption.org/)**: File encryption
- **[Task](https://taskfile.dev)**: Task automation
- **[mise](https://mise.jdx.dev/)**: Tool version management
- **[Fish](https://fishshell.com/)**: Shell
- **[Homebrew](https://brew.sh)**: Package management

## Encryption

Sensitive files are encrypted with age using two systems:

### Chezmoi-Managed

Files like `encrypted_*.age` in `chezmoi/` source:

```bash
chezmoi add --encrypt ~/.config/sensitive-file
chezmoi edit ~/.config/sensitive-file
```

### Git-Filter Managed

Files in `.gitattributes` (CLAUDE.md, secrets/, todos/):

- Automatically encrypted on commit
- Automatically decrypted on checkout
- Transparent to git operations

Both systems use multi-recipient encryption (personal + CI keys).

## Documentation

- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development workflow and guidelines
- **[TESTING.md](TESTING.md)** - Testing and CI/CD
- **[TROUBLESHOOTING.md](TROUBLESHOOTING.md)** - Common issues and debugging
- **[SECURITY.md](SECURITY.md)** - Security policy and vulnerability reporting

## Testing

Tests run automatically in CI on every push:

```bash
task test           # Run all tests
task lint           # Run all linters
```

See [TESTING.md](TESTING.md) for details.

## License

MIT License - see [LICENSE](LICENSE) for details.
