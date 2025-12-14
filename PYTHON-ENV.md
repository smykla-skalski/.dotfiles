# Python Development Environment

Per-project Python environments with automatic activation via direnv.

## Architecture

```text
┌─────────────────────────────────────────────────────────────────────┐
│                         Project Directory                            │
│  ┌──────────────┐  ┌──────────────┐  ┌────────────────────────────┐ │
│  │ .mise.toml   │  │ pyproject.   │  │ .envrc                     │ │
│  │ python=3.12  │  │ toml         │  │ use_python_env             │ │
│  └──────┬───────┘  └──────┬───────┘  └─────────────┬──────────────┘ │
└─────────┼─────────────────┼────────────────────────┼────────────────┘
          │                 │                        │
          ▼                 │                        ▼
┌─────────────────┐         │         ┌──────────────────────────────┐
│ Version Check   │         │         │ direnv + use_python_env()    │
│                 │         │         │ ~/.config/direnv/direnvrc    │
│ In nixpkgs?     │         │         └──────────────┬───────────────┘
│ 3.10-3.13: Yes  │         │                        │
│ 3.14+: No       │         │                        ▼
└────────┬────────┘         │         ┌──────────────────────────────┐
         │                  │         │ Python Interpreter           │
         ▼                  │         │                              │
┌─────────────────┐         │         │ nix (3.10-3.13)              │
│ nix-direnv      │◄────────┼─────────│ OR                           │
│ shell.nix       │         │         │ mise (3.14+)                 │
└─────────────────┘         │         └──────────────┬───────────────┘
                            │                        │
                            ▼                        ▼
                  ┌─────────────────┐  ┌──────────────────────────────┐
                  │ Package Source  │  │ uv                           │
                  │                 │  │                              │
                  │ pyproject.toml  │──│ uv sync --all-groups         │
                  │ OR              │  │ OR                           │
                  │ requirements.txt│──│ uv pip install -r            │
                  └─────────────────┘  └──────────────┬───────────────┘
                                                      │
                                                      ▼
                                       ┌──────────────────────────────┐
                                       │ .venv/                       │
                                       │ ├── bin/python               │
                                       │ └── lib/python3.x/           │
                                       │     └── site-packages/       │
                                       └──────────────────────────────┘
```

## Key Design Decisions

**Package installer:** uv - Respects version specifiers, fast, handles all dependency formats

**Python source (3.10-3.13):** nixpkgs - Stable, cached, reproducible

**Python source (3.14+):** mise - Bleeding edge versions not yet in nixpkgs

**Environment type:** Real `.venv/` - IDE compatibility, standard Python tooling

**Activation:** direnv - Automatic on `cd`, shell-agnostic

## File Locations

### Central Infrastructure

- `nix/modules/home/direnv.nix` - Main implementation of `use_python_env()` function
- `nix/python-env/shell.nix` - Nix shell that provides Python interpreter
- `nix/python-env/nixpkgs-python-versions.json` - List of Python versions available in nixpkgs

### Per-Project Files

- `.envrc` - Contains `use_python_env` (created by user or Fish auto-detection)
- `.venv/` - Virtual environment (created by `uv venv`)
- `.direnv/` - direnv cache (created by direnv)
- `.direnv/python-shell.nix` - Generated nix expression (created by `use_python_env()`)

## How It Works

### 1. Version Detection

When `use_python_env()` runs, it checks mise config files in this order:

1. `.mise.local.toml`
2. `.mise.toml`
3. `mise.local.toml`
4. `mise.toml`
5. `.config/mise.toml`
6. `.config/mise/config.toml`
7. `.tool-versions` (legacy asdf format)

**TOML format:** `python = "3.12"`

**tool-versions format:** `python 3.12`

### 2. Interpreter Selection

```text
Version requested → Check nixpkgs-python-versions.json → Decision
                                                          │
                    ┌─────────────────────────────────────┴───────────┐
                    │                                                 │
                    ▼                                                 ▼
            Version in nixpkgs                              Version NOT in nixpkgs
            (3.10, 3.11, 3.12, 3.13)                        (3.14+)
                    │                                                 │
                    ▼                                                 ▼
            Generate .direnv/python-shell.nix               mise use python@X.Y
            use nix .direnv/python-shell.nix                export PATH
```

### 3. Package Installation

```text
Package source detected?
        │
        ├── pyproject.toml exists
        │   └── uv sync --all-groups
        │       (handles [project.dependencies],
        │        [project.optional-dependencies],
        │        [dependency-groups])
        │
        ├── requirements.txt exists
        │   └── uv pip install -r requirements.txt
        │
        └── Neither exists
            └── Bare Python (stdlib only)
```

### 4. Environment Activation

After setup, these environment variables are set:

```bash
VIRTUAL_ENV=/path/to/project/.venv
PATH=/path/to/project/.venv/bin:$PATH
```

## Usage

### Basic Usage

```bash
# In any project directory with pyproject.toml or requirements.txt
echo 'use_python_env' > .envrc
direnv allow
```

### With Specific Python Version

```bash
# Create mise config
echo '[tools]
python = "3.12"' > .mise.toml

# Create .envrc
echo 'use_python_env' > .envrc
direnv allow
```

### Quiet Mode

```bash
echo 'use_python_env --quiet' > .envrc
direnv allow
```

## Activation Message

When environment activates, you'll see:

```text
🐍 Python 3.12.8 (nix) + uv
   Packages: 15 from pyproject.toml
   IDE path: .venv/bin/python
```

Or for mise-provided Python:

```text
🐍 Python 3.14.2 (mise) + uv
   Packages: 10 from requirements.txt
   IDE path: .venv/bin/python
```

## IDE Integration

The `.venv/bin/python` path is standard and auto-detected by:

- VS Code (Python extension)
- PyCharm / IntelliJ
- Vim/Neovim (with LSP)

No additional configuration needed.

## Troubleshooting

### Environment Not Activating

```bash
# Check direnv is allowed
direnv status

# Re-allow if needed
direnv allow
```

### Wrong Python Version

```bash
# Check what mise resolves
mise which python
mise config --local

# Verify version in .venv
.venv/bin/python --version
```

### Packages Not Installing

```bash
# Check uv is available
which uv

# Manually sync
uv sync --all-groups

# Check installed packages
uv pip list
```

### Stale Environment

```bash
# Remove cached environment and re-allow
rm -rf .venv .direnv
direnv allow
```

### Check Generated Nix File (nix mode)

```bash
cat .direnv/python-shell.nix
```

## Extending

### Adding New Python Version to nixpkgs Support

Edit `nix/python-env/nixpkgs-python-versions.json`:

```json
{
  "versions": ["310", "311", "312", "313", "314"],
  "default": "313"
}
```

And update `nix/python-env/shell.nix` to include the new version mapping.

### Custom Package Sources

The function only supports `pyproject.toml` and `requirements.txt`. For other formats, pre-process them into one of these formats.

## Related Files

- `CLAUDE.md` - Contains user-facing documentation in "Python Development Environment" section
- `nix/modules/home/packages.nix` - Installs `uv` globally
