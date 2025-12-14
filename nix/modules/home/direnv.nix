# Direnv configuration
#
# Migrated from chezmoi to home-manager programs.direnv.
# Direnv provides per-directory environment variable management.
#
# Fish integration is automatic when programs.fish.enable = true.
{ config, lib, pkgs, ... }:

let
  # Path to the python environment files (relative to dotfiles)
  pythonEnvPath = "${config.home.homeDirectory}/Projects/github.com/smykla-labs/.dotfiles/nix/python-env";
  nixpkgsPythonVersionsPath = "${pythonEnvPath}/nixpkgs-python-versions.json";
in
{
  programs.direnv = {
    enable = true;

    # Override to use git master with log_format fix (PR #1476)
    # https://github.com/direnv/direnv/pull/1476
    # TODO: Remove once direnv 2.38.0+ is released
    package = pkgs.direnv.overrideAttrs (oldAttrs: rec {
      version = "2.37.1-unstable-2025-07-30";
      src = pkgs.fetchFromGitHub {
        owner = "direnv";
        repo = "direnv";
        rev = "92436eed264bc286862c5cce6fff2781cd195778";  # PR #1476 merge commit
        hash = "sha256-H75lGBk1wqWV/OrcgRvkUIDycaz6wAFVqdvIucDLyuw=";
      };
    });

    # Use nix-direnv for faster nix shell loading
    nix-direnv.enable = true;

    config = {
      global = {
        # Disable loading/unloading messages
        log_format = "-";

        # Hide environment diff output
        hide_env_diff = true;
      };
    };

    # Custom stdlib functions for direnv
    # This is written to ~/.config/direnv/direnvrc
    stdlib = ''
      # use_python_env - Dynamic Python environment with uv package management
      #
      # Architecture:
      #   - Nix provides Python interpreter (version from mise config or default)
      #   - uv always installs packages from PyPI (respects version specifiers)
      #
      # Python version selection:
      #   - Reads from .mise.toml or .tool-versions
      #   - For versions in nixpkgs (3.10-3.13): uses nix Python
      #   - For versions not in nixpkgs (3.14+): uses mise Python
      #
      # Supported package formats:
      #   - pyproject.toml (dependencies, optional-dependencies, dependency-groups)
      #   - requirements.txt
      #
      # Usage in .envrc:
      #   use_python_env           # Normal mode with activation message
      #   use_python_env --quiet   # Suppress activation message
      #
      use_python_env() {
        local python_shell_nix="''${PYTHON_SHELL_NIX:-${pythonEnvPath}/shell.nix}"
        local nixpkgs_versions_json="''${NIXPKGS_PYTHON_VERSIONS:-${nixpkgsPythonVersionsPath}}"
        local packages_source=""
        local quiet=false
        local mise_python_version=""
        local nixpkgs_python_version=""
        local use_mise_python=false

        # Parse arguments
        while [[ $# -gt 0 ]]; do
          case "$1" in
            --quiet|-q)
              quiet=true
              shift
              ;;
            *)
              shift
              ;;
          esac
        done

        # Parse Python version from mise config files
        # Checks all supported mise config locations in precedence order
        _get_mise_python_version() {
          local version=""
          local toml_files=(
            ".mise.local.toml"
            ".mise.toml"
            "mise.local.toml"
            "mise.toml"
            ".config/mise.toml"
            ".config/mise/config.toml"
          )

          # Check TOML config files (format: python = "3.11")
          for toml_file in "''${toml_files[@]}"; do
            if [[ -f "$toml_file" ]]; then
              version="$(grep -E '^python\s*=' "$toml_file" 2>/dev/null | awk -F'"' '{print $2}' | head -1)"
              if [[ -n "$version" ]]; then
                echo "$version"
                return
              fi
            fi
          done

          # Check .tool-versions (legacy asdf format: python 3.11)
          if [[ -f .tool-versions ]]; then
            version="$(grep -E '^python\s+' .tool-versions 2>/dev/null | awk '{print $2}' | head -1)"
            if [[ -n "$version" ]]; then
              echo "$version"
              return
            fi
          fi
        }

        # Convert version like "3.11" to nixpkgs format "311"
        _version_to_nixpkgs_format() {
          echo "$1" | sed -E 's/^([0-9]+)\.([0-9]+).*/\1\2/'
        }

        # Check if nixpkgs has the given Python version
        _nixpkgs_has_python_version() {
          local version="$1"
          if [[ -f "$nixpkgs_versions_json" ]] && command -v jq &> /dev/null; then
            jq -e --arg v "$version" '.versions | index($v) != null' "$nixpkgs_versions_json" > /dev/null 2>&1
            return $?
          fi
          [[ "$version" =~ ^31[0-3]$ ]]
        }

        # Determine Python source (nix or mise)
        mise_python_version="$(_get_mise_python_version)"
        if [[ -n "$mise_python_version" ]]; then
          nixpkgs_python_version="$(_version_to_nixpkgs_format "$mise_python_version")"
          if ! _nixpkgs_has_python_version "$nixpkgs_python_version"; then
            use_mise_python=true
          fi
        fi

        # Determine package source
        if [[ -f pyproject.toml ]]; then
          packages_source="pyproject.toml"
        elif [[ -f requirements.txt ]]; then
          packages_source="requirements.txt"
        fi

        # Setup Python interpreter
        mkdir -p .direnv

        if [[ "$use_mise_python" == "true" ]]; then
          # Use mise for Python (version not in nixpkgs)
          if ! mise which python &> /dev/null; then
            log_status "Installing Python $mise_python_version via mise..."
            mise use "python@$mise_python_version"
          fi
          local python_path
          python_path="$(mise which python 2>/dev/null)"
          if [[ -z "$python_path" ]]; then
            log_error "Failed to get Python path from mise"
            return 1
          fi
          export PATH="$(dirname "$python_path"):$PATH"
        else
          # Use nix for Python
          cat > .direnv/python-shell.nix << NIXEOF
      # Generated by use_python_env - do not edit manually
      import (/. + "${pythonEnvPath}/shell.nix") {
        quiet = true;
        pythonVersion = "$nixpkgs_python_version";
      }
      NIXEOF
          use nix .direnv/python-shell.nix
        fi

        # Create/update venv and install packages using uv
        local python_bin
        python_bin="$(command -v python3 2>/dev/null)"

        if [[ -z "$python_bin" ]]; then
          log_error "Python not found in PATH"
          return 1
        fi

        # Create venv if needed
        if [[ ! -d .venv ]] || [[ ! -f .venv/pyvenv.cfg ]]; then
          rm -rf .venv 2>/dev/null || true
          uv venv --python "$python_bin" .venv --quiet
        fi

        # Activate venv (don't set VIRTUAL_ENV - let uv auto-detect .venv)
        export PATH="$PWD/.venv/bin:$PATH"

        # Install packages from PyPI via uv
        if [[ -n "$packages_source" ]]; then
          if [[ "$packages_source" == "pyproject.toml" ]]; then
            # Use uv sync for pyproject.toml - handles dependencies, optional-dependencies, and dependency-groups
            uv sync --quiet --all-groups 2>/dev/null || uv sync --quiet 2>/dev/null || true
          elif [[ "$packages_source" == "requirements.txt" ]]; then
            uv pip install --quiet -r requirements.txt
          fi
        fi

        # Output activation message
        if [[ "$quiet" != "true" ]]; then
          local python_version pkg_count
          python_version="$(.venv/bin/python --version 2>&1 | awk '{print $2}')"
          pkg_count="$(uv pip list 2>/dev/null | tail -n +3 | wc -l | tr -d ' ')"

          if [[ "$use_mise_python" == "true" ]]; then
            echo "🐍 Python $python_version (mise) + uv"
          else
            echo "🐍 Python $python_version (nix) + uv"
          fi
          echo "   Packages: $pkg_count from $packages_source"
          echo "   IDE path: .venv/bin/python"
        fi

        # Add .venv to git exclude
        if [[ -e .git ]]; then
          local git_dir exclude_file
          git_dir="$(git rev-parse --git-dir 2>/dev/null)"
          if [[ -n "$git_dir" ]]; then
            exclude_file="$git_dir/info/exclude"
            mkdir -p "$git_dir/info"
            for pattern in .envrc .direnv/ .venv; do
              grep -qxF "$pattern" "$exclude_file" 2>/dev/null || echo "$pattern" >> "$exclude_file"
            done
          fi
        fi
      }
    '';
  };
}
