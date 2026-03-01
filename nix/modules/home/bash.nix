# Bash shell configuration
#
# Migrated from chezmoi to home-manager programs.bash.
# Configures .bashrc and .profile for non-interactive and login shell scenarios.
#
# Note: macOS ships with bash 3.2. Home-manager defaults enable bash 4+ features
# (globstar, checkjobs, -v test operator). We disable these defaults and add
# version guards to support both system bash and nix-managed bash 5.x.
{ config, lib, pkgs, ... }:

{
  # Create .bash_env for non-interactive shells (used by BASH_ENV)
  home.file.".bash_env" = {
    text = ''
      # Non-interactive bash environment
      # This file is sourced by non-interactive bash shells (like make, Claude Code, etc.)
      # via BASH_ENV environment variable

      # Prevent "unbound variable" errors in strict mode (set -u)
      # PROMPT_COMMAND is typically set by interactive shells but not in non-interactive mode
      : "''${PROMPT_COMMAND:=}"

      # Enable alias expansion in non-interactive shells (required for aliases to work)
      shopt -s expand_aliases

      # Suppress pkg_resources deprecation warning from kathara_lab_checker
      export PYTHONWARNINGS="ignore::UserWarning"

      # Add ~/.local/bin to PATH for mise executable
      export PATH="$HOME/.local/bin:$PATH"

      # Claude Code skills CLI wrapper
      export PATH="$HOME/Projects/github.com/smykla-skalski/research/claude-code/skills/_bin:$PATH"

      # klab - Kubernetes networking labs
      export PATH="$HOME/Projects/github.com/smykla-skalski/klab/.bin:$PATH"

      # Activate mise for non-interactive shells using hook-env for better version resolution
      # hook-env respects PWD and per-project .mise.toml files, ensuring correct tool versions
      # This is used by Claude Code CLI, make, and other non-interactive bash invocations
      # Uses hook-env instead of activate for consistent behavior with per-directory configs
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise hook-env -s bash)"
      fi

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"
    '';
    force = true;  # Overwrite existing .bash_env
  };

  programs.bash = {
    enable = true;

    # Disable home-manager defaults that require bash 4+
    # We'll add version-guarded equivalents in initExtra
    enableCompletion = false;
    shellOptions = [ "histappend" "extglob" ];  # Only bash 3.2-compatible options

    # .bashrc content (interactive shells)
    initExtra = ''
      # Suppress pkg_resources deprecation warning from kathara_lab_checker
      export PYTHONWARNINGS="ignore::UserWarning"

      # Enable bash 4+ features only when available
      if [[ ''${BASH_VERSINFO[0]} -ge 4 ]]; then
        shopt -s globstar checkjobs

        # Bash completion (requires bash 4.2+ -v operator)
        if [[ ''${BASH_VERSINFO[0]} -gt 4 || (''${BASH_VERSINFO[0]} -eq 4 && ''${BASH_VERSINFO[1]} -ge 2) ]]; then
          if [[ -z "''${BASH_COMPLETION_VERSINFO+set}" ]]; then
            if [[ -f "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh" ]]; then
              . "${pkgs.bash-completion}/etc/profile.d/bash_completion.sh"
            fi
          fi
        fi
      fi

      # Add ~/.local/bin to PATH for mise and other tools
      export PATH="$HOME/.local/bin:$PATH"

      # Claude Code skills CLI wrapper
      export PATH="$HOME/Projects/github.com/smykla-skalski/research/claude-code/skills/_bin:$PATH"

      # klab - Kubernetes networking labs
      export PATH="$HOME/Projects/github.com/smykla-skalski/klab/.bin:$PATH"

      # Set BASH_ENV for non-interactive subshells (needed by make)
      export BASH_ENV="$HOME/.bash_env"

      # Python shell.nix location for direnv
      export DOTFILES_PATH="$HOME/Projects/github.com/smykla-skalski/.dotfiles"
      export PYTHON_SHELL_NIX="$DOTFILES_PATH/nix/python-env/shell.nix"

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # fzf integration
      [ -f ~/.fzf.bash ] && source ~/.fzf.bash

      # broot integration
      [ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

      # Activate mise for interactive shells (prompt hook re-evaluates on cd)
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate bash)"
      fi
    '';

    # .profile content (login shells)
    profileExtra = ''
      # NOTE: mise integration manually configured in bash.nix (not using enableBashIntegration)
      # Uses 'mise hook-env' in BASH_ENV for non-interactive shells (Claude Code, make, etc.)
      # Uses 'mise activate' in .bashrc for interactive shells with prompt hooks
      # Shims are NOT used - mise modifies PATH directly with tool directories

      # Set BASH_ENV so non-interactive bash shells (like make) can find mise
      export BASH_ENV="$HOME/.bash_env"

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
    '';
  };
}
