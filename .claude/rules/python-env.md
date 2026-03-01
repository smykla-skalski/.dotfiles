# Python Development Environment

Dynamic Python environments with **direnv** per-project activation. Packages are read from `requirements.txt` or `pyproject.toml`. Python version specified via **mise** config files.

## Quick Start

**Automatic**: `cd` into any directory with `requirements.txt` or `pyproject.toml`. Fish shell automatically:

1. Creates `.envrc` with `use_python_env`
2. Adds `.envrc` to `.git/info/exclude` (including all worktrees)
3. Runs `direnv allow`

**Manual**: If auto-detection doesn't trigger:

```bash
echo 'use_python_env' > .envrc        # With activation message
echo 'use_python_env --quiet' > .envrc # Silent mode
direnv allow
```

Environment auto-loads on `cd`, reading packages from:

1. `pyproject.toml` (via `uv sync --all-groups`) - handles `[project].dependencies`, `[project.optional-dependencies]`, and `[dependency-groups]`
2. `requirements.txt` (via `uv pip install -r`) - fallback if no pyproject.toml
3. Bare environment (stdlib only) if neither exists

## Files

**Project files**:

```text
your-project/
├── .envrc              # Auto-created: use_python_env
├── .mise.toml          # python = "3.11"
├── requirements.txt    # requests>=2.28.0
└── pyproject.toml      # [project.dependencies], etc.
```

**Supported mise config files** (precedence order):

1. `.mise.local.toml` - Local overrides (gitignored)
2. `.mise.toml` - Project config (recommended)
3. `mise.local.toml` - Local overrides without dot prefix
4. `mise.toml` - Project config without dot prefix
5. `.config/mise.toml` - XDG-style config
6. `.config/mise/config.toml` - XDG-style nested config
7. `.tool-versions` - Legacy asdf format

**Central infrastructure** (`$DOTFILES_PATH/nix/python-env/`):

- `shell.nix` - Parameterized nix shell providing Python interpreter
- `nixpkgs-python-versions.json` - Available Python versions in nixpkgs

## How It Works

1. `use_python_env` reads Python version from mise config files
2. Mode selection:
   - **Nix mode** (3.10-3.13): Uses nixpkgs Python interpreter
   - **mise mode** (3.14+): Uses mise to install Python
3. Creates `.venv` using `uv venv`
4. Installs packages via uv
5. nix-direnv caches environments (~750ms faster after first load)

## Python Version Selection

```toml
# .mise.toml
[tools]
python = "3.11"    # Uses nixpkgs python311
# python = "3.14"  # Falls back to mise + uv (not in nixpkgs)
```

Or `.tool-versions`:

```text
python 3.12
```

**Mode selection**:

| Version   | Python Source | Package Source |
|-----------|---------------|----------------|
| 3.10-3.13 | nixpkgs       | PyPI (via uv)  |
| 3.14+     | mise          | PyPI (via uv)  |

## IDE Integration

`.venv` directory auto-created. IDEs (VS Code, PyCharm) auto-detect `.venv/bin/python`.

**Environment variables set:**

- `PYTHONPATH` - Points to site-packages
- `VIRTUAL_ENV` - Points to `.venv`

**IDE interpreter path:** `.venv/bin/python`

## Troubleshooting

**Old environment cached**:

```bash
rm -rf .direnv .venv && direnv allow
```

**Check generated nix file (nix mode)**:

```bash
cat .direnv/python-shell.nix
```

**mise+uv mode not installing packages**:

```bash
which uv
ls -la .venv/bin/
```

**Wrong Python version**:

```bash
mise which python           # Check Python resolution
mise config --local         # Show local mise config
```

## Resources

- [PYTHON-ENV.md](../PYTHON-ENV.md) - Architecture and implementation details
- [Fixing Python Import Resolution in Nix with Direnv](https://cyberchris.xyz/posts/nix-python-pyright/)
- [nix-direnv Performance](https://ianthehenry.com/posts/how-to-learn-nix/nix-direnv/)
- [Simple Python devshells](https://sgt.hootr.club/blog/python-nix-shells/)
