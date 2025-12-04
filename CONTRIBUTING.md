# Contributing to .dotfiles

Thank you for your interest in contributing! This document provides guidelines for contributing to this dotfiles repository.

## Getting Started

### Prerequisites

- macOS (tested on macOS 15)
- [Homebrew](https://brew.sh)
- Git with GPG signing configured
- [mise](https://mise.jdx.dev/) for tool management

### Setup Development Environment

#### Option 1: Automated Setup (Recommended for Fresh Machines)

Use the bootstrap script for quick setup:

```bash
curl -fsSL https://smyk.la | bash
```

This automatically handles all dependencies, encryption setup, and configuration. See [https://smyk.la](https://smyk.la) for options.

After bootstrap completes, add the upstream remote if working from a fork:

```bash
cd ~/Projects/github.com/smykla-labs/.dotfiles
git remote add upstream https://github.com/smykla-labs/.dotfiles
```

#### Option 2: Manual Setup

1. Fork and clone the repository:

   ```bash
   git clone https://github.com/YOUR_USERNAME/.dotfiles ~/Projects/github.com/YOUR_USERNAME/.dotfiles
   cd ~/Projects/github.com/YOUR_USERNAME/.dotfiles
   ```

2. Add upstream remote:

   ```bash
   git remote add upstream https://github.com/smykla-labs/.dotfiles
   ```

3. Install dependencies:

   ```bash
   mise install
   brew bundle install --file=Brewfile
   ```

4. Install git hooks (recommended):

   ```bash
   task hooks:install
   ```

   This installs:
   - **pre-commit**: Runs `task lint` before each commit
   - **pre-push**: Runs `task test` before each push

## Development Workflow

### Making Changes

1. Create a new branch from main:

   ```bash
   git checkout main
   git fetch upstream
   git rebase upstream/main
   git checkout -b your-feature-branch
   ```

2. Make your changes in the appropriate location:
   - Dotfiles: `nix/modules/` (nix/home-manager configuration)
   - Documentation: `docs/`, root `.md` files
   - Tasks: `Taskfile.yaml`
   - CI: `.github/workflows/`

3. Test your changes:

   ```bash
   task test          # Run all tests
   task lint          # Run all linters
   ```

### Commit Guidelines

Follow [Conventional Commits](https://conventionalcommits.org/) format:

```text
type(scope): description

Body (optional, max 72 chars per line)

Footer (optional)
```

#### Commit Types

Use specific types for infrastructure changes:

| Type       | Use Case                | Example                                       |
|:-----------|:------------------------|:----------------------------------------------|
| `feat`     | New user-facing feature | `feat(fish): add git helper function`         |
| `fix`      | Bug fix                 | `fix(nix): correct age encryption path`       |
| `docs`     | Documentation only      | `docs(readme): add installation steps`        |
| `ci`       | CI/CD changes           | `ci(workflow): add macos-14 to test matrix`   |
| `test`     | Test changes            | `test(fish): add syntax validation`           |
| `chore`    | Maintenance tasks       | `chore(deps): update shellcheck to 0.10.0`    |
| `refactor` | Code refactoring        | `refactor(fish): simplify git push functions` |
| `build`    | Build system changes    | `build(taskfile): add new lint task`          |

**Important**: Use `ci(...)` not `fix(ci)`, `test(...)` not `feat(test)`, etc.

#### Commit Signing

All commits must be signed with `-sS`:

```bash
git commit -sS -m "type(scope): description"
```

#### Commit Message Format

- **Title**: Max 50 characters, use backticks for code/commands/files
- **Body**: Max 72 characters per line, explain "why" not "what"
- **No AI footer**: Remove Claude Code attribution

**Good examples**:

```bash
git commit -sS -m "feat(fish): add kubernetes context switcher

Add \`kctx\` function for quick context switching with fzf integration.
Improves workflow when working with multiple clusters."
```

```bash
git commit -sS -m "docs(age): document key rotation process"
```

**Bad examples**:

```bash
# Too vague
git commit -m "fix stuff"

# Wrong type (should be ci, not fix)
git commit -m "fix(ci): update workflow"

# Not signed
git commit -m "feat(fish): add function"
```

### Testing Requirements

All changes must pass testing:

```bash
task test && task lint
```

#### Test Coverage

- **Shell scripts**: Must pass `shellcheck`
- **Fish functions**: Must have valid syntax (`fish -n`)
- **Markdown**: Must pass `markdownlint`
- **Taskfile**: Must validate against schema

See [TESTING.md](TESTING.md) for comprehensive testing documentation.

### Pull Request Process

1. Ensure all tests pass locally
2. Push your branch to your fork:

   ```bash
   git push origin your-feature-branch
   ```

3. Create a pull request:

   ```bash
   gh pr create --base main --head YOUR_USERNAME:your-feature-branch
   ```

4. Fill in the PR template:
   - Clear description of changes
   - Link related issues
   - Include test results if applicable

5. Respond to review feedback and update PR as needed

## Code Style Guidelines

### Shell Scripts

- Use long flags for readability: `--force` not `-f`
- Must pass `shellcheck` with no warnings
- Add descriptions to Fish functions: `--description "..."` or `-d "..."`
- Use proper error handling

### Documentation

- Use Markdown for all documentation
- Add blank line after all headers
- Use backticks for code, commands, file paths
- Keep lines readable (no hard limit, but be reasonable)
- Capitalize "Markdown" not "markdown"

### Taskfile

- Group related tasks with comments
- Use descriptive task names: `test:fish` not `tf`
- Include `desc:` for all tasks
- Use `sources:` and `generates:` for caching
- Validate against schema: `task lint:taskfile`

## Project Structure

```text
.dotfiles/
├── nix/                       # Nix configuration
│   ├── flake.nix              # Flake entry point
│   ├── flake.lock             # Locked dependencies
│   ├── modules/               # Nix modules
│   │   ├── darwin/            # nix-darwin modules (system-level)
│   │   └── home/              # home-manager modules (user-level)
│   └── secrets/               # sops-nix encrypted secrets
├── .github/
│   └── workflows/
│       ├── codeql.yaml        # CodeQL security analysis
│       ├── scorecards.yaml    # OpenSSF Scorecard
│       └── test.yaml          # CI/CD pipeline
├── hooks/                     # Git hooks
│   ├── pre-commit             # Lint check
│   └── pre-push               # Test check
├── spec/                      # ShellSpec tests
├── Taskfile.yaml              # Task automation
├── Brewfile                   # Homebrew packages (legacy)
├── README.md                  # Project overview
├── CONTRIBUTING.md            # This file
├── SECURITY.md                # Security policy
└── TESTING.md                 # Testing documentation
```

## Encryption

The dotfiles use age encryption for sensitive files via git filters.

### Nix Secrets (sops-nix)

Secrets in `nix/secrets/secrets.yaml`:

- Edit: `SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml`
- Deployed by Home Manager

### Git-Filter Files

Files automatically encrypted via `.gitattributes` (CLAUDE.md, secrets/, todos/):

- Encrypted transparently on `git add`
- Decrypted automatically on checkout
- Uses `.git/age-clean.sh` (encrypt) and age smudge filter (decrypt)

### Key Management

- **Personal key**: `~/.config/age/key.txt` (never commit)
- **CI key**: Stored in `AGE_CI_KEY` GitHub Secret
- Both keys can decrypt files (multi-recipient encryption)

**Never commit**:

- Plain-text secrets
- Age private keys
- Personal API tokens

## Getting Help

- [TESTING.md](TESTING.md) - Testing and CI/CD
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - Debugging and common issues
- [SECURITY.md](SECURITY.md) - Security policy and vulnerability reporting
- [README.md](README.md) - Quick start and overview
- Open an issue for bugs or feature requests

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
