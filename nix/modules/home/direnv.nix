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
      # use_python_env - Dynamic Python environment from requirements.txt or pyproject.toml
      #
      # Parses Python package requirements, maps pip names to nixpkgs names,
      # and creates a nix shell environment with the resolved packages.
      #
      # Supported formats:
      #   - requirements.txt (pip format)
      #   - pyproject.toml ([project.dependencies] section)
      #
      # Usage in .envrc:
      #   use_python_env           # Normal mode with activation message
      #   use_python_env --quiet   # Suppress activation message
      #
      use_python_env() {
        local python_shell_nix="''${PYTHON_SHELL_NIX:-${pythonEnvPath}/shell.nix}"
        local pip_to_nix_json="''${PYTHON_PIP_TO_NIX:-${pythonEnvPath}/pip-to-nix.json}"
        local packages=()
        local packages_source=""
        local quiet=false

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

        # Function to normalize package names (lowercase, underscores to hyphens)
        _normalize_pkg_name() {
          echo "$1" | tr '[:upper:]' '[:lower:]' | tr '_' '-'
        }

        # Function to extract package name from requirement line
        # Handles: package, package==1.0, package>=1.0, package[extra], etc.
        _extract_pkg_name() {
          local line="$1"
          # Remove leading/trailing whitespace
          line="$(echo "$line" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
          # Skip empty lines and comments
          [[ -z "$line" || "$line" =~ ^# ]] && return
          # Skip -r, -e, -i, --index-url, etc.
          [[ "$line" =~ ^- ]] && return
          # Extract package name (before version specifiers, extras, etc.)
          local pkg
          pkg="$(echo "$line" | sed -E 's/^([a-zA-Z0-9_-]+).*/\1/')"
          _normalize_pkg_name "$pkg"
        }

        # Parse pyproject.toml [project.dependencies]
        _parse_pyproject_toml() {
          local in_dependencies=false
          local line pkg

          while IFS= read -r line; do
            # Check for [project.dependencies] or dependencies = [
            if [[ "$line" =~ ^\[project\]$ ]]; then
              in_dependencies=false
            elif [[ "$line" =~ ^dependencies[[:space:]]*=[[:space:]]*\[ ]]; then
              in_dependencies=true
              # Handle inline array on same line
              if [[ "$line" =~ \] ]]; then
                # Single-line array: dependencies = ["pkg1", "pkg2"]
                line="$(echo "$line" | sed -E 's/.*\[([^]]*)\].*/\1/')"
                for item in $(echo "$line" | tr ',' '\n'); do
                  item="$(echo "$item" | tr -d '"'"'"' ')"
                  pkg="$(_extract_pkg_name "$item")"
                  [[ -n "$pkg" ]] && packages+=("$pkg")
                done
                in_dependencies=false
              fi
              continue
            elif [[ "$line" =~ ^\[ ]] && [[ ! "$line" =~ ^\[project\] ]]; then
              in_dependencies=false
            fi

            if $in_dependencies; then
              # End of array
              if [[ "$line" =~ ^\] ]]; then
                in_dependencies=false
                continue
              fi
              # Extract package from quoted string
              line="$(echo "$line" | tr -d '"'"'"',' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
              pkg="$(_extract_pkg_name "$line")"
              [[ -n "$pkg" ]] && packages+=("$pkg")
            fi
          done < pyproject.toml
        }

        # Parse requirements.txt
        _parse_requirements_txt() {
          local line pkg
          while IFS= read -r line || [[ -n "$line" ]]; do
            pkg="$(_extract_pkg_name "$line")"
            [[ -n "$pkg" ]] && packages+=("$pkg")
          done < requirements.txt
        }

        # Determine which file to parse
        if [[ -f pyproject.toml ]]; then
          if grep -q '^\[project\]' pyproject.toml && grep -q 'dependencies' pyproject.toml; then
            packages_source="pyproject.toml"
            _parse_pyproject_toml
          elif [[ -f requirements.txt ]]; then
            packages_source="requirements.txt"
            _parse_requirements_txt
          fi
        elif [[ -f requirements.txt ]]; then
          packages_source="requirements.txt"
          _parse_requirements_txt
        fi

        # Map pip names to nix names using jq
        local nix_packages=()
        local nix_pkg pip_pkg

        if [[ -f "$pip_to_nix_json" ]] && command -v jq &> /dev/null; then
          for pip_pkg in "''${packages[@]}"; do
            nix_pkg="$(jq -r --arg pip "$pip_pkg" '.[$pip] // $pip' "$pip_to_nix_json")"
            nix_packages+=("$nix_pkg")
          done
        else
          # Fallback: use pip names directly if jq or mapping not available
          nix_packages=("''${packages[@]}")
        fi

        # Generate .direnv/python-shell.nix
        mkdir -p .direnv

        # Build nix package list string
        local nix_pkg_list=""
        for pkg in "''${nix_packages[@]}"; do
          nix_pkg_list="$nix_pkg_list \"$pkg\""
        done

        cat > .direnv/python-shell.nix << NIXEOF
      # Generated by use_python_env - do not edit manually
      # Source: ''${packages_source:-none}
      # Packages: ''${packages[*]:-none}
      import (/. + "${pythonEnvPath}/shell.nix") {
        packages = [$nix_pkg_list ];
        quiet = $quiet;
      }
      NIXEOF

        # Use nix-direnv's use nix function
        use nix .direnv/python-shell.nix

        # Create .venv symlink for IDE detection (runs every load, very fast)
        local python_path python_env
        python_path="$(command -v python3 2>/dev/null)"
        if [[ -n "$python_path" ]]; then
          python_env="''${python_path%/bin/python3}"
          if [[ ! -L .venv ]] || [[ "$(readlink .venv 2>/dev/null)" != "$python_env" ]]; then
            rm -rf .venv 2>/dev/null || true
            ln -sf "$python_env" .venv
          fi
          export VIRTUAL_ENV="$PWD/.venv"

          # Add .venv to git exclude if in a git repo (idempotent, very fast)
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
        fi
      }
    '';
  };
}
