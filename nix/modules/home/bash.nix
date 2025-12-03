# Bash shell configuration
#
# Migrated from chezmoi to home-manager programs.bash.
# Configures .bashrc and .profile for non-interactive and login shell scenarios.
{ config, lib, pkgs, ... }:

{
  # Create .bash_env for non-interactive shells (used by BASH_ENV)
  home.file.".bash_env" = {
    text = ''
      # Non-interactive bash environment
      # This file is sourced by non-interactive bash shells (like make, Claude Code, etc.)
      # via BASH_ENV environment variable

      # Enable alias expansion in non-interactive shells (required for aliases to work)
      shopt -s expand_aliases

      # Add ~/.local/bin to PATH for mise executable
      export PATH="$HOME/.local/bin:$PATH"

      # For non-interactive shells, use mise hook-env instead of activate
      # This sets up PATH and other environment variables immediately
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

    # .bashrc content (interactive shells)
    initExtra = ''
      # Add ~/.local/bin to PATH for mise and other tools
      export PATH="$HOME/.local/bin:$PATH"

      # Set BASH_ENV for non-interactive subshells (needed by make)
      export BASH_ENV="$HOME/.bash_env"

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # mise - tool version manager
      if command -v mise &> /dev/null; then
        eval "$(mise activate bash)"
      fi

      # fzf integration
      [ -f ~/.fzf.bash ] && source ~/.fzf.bash

      # broot integration
      [ -f "$HOME/.config/broot/launcher/bash/br" ] && source "$HOME/.config/broot/launcher/bash/br"

      # Rancher Desktop
      [ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"
    '';

    # .profile content (login shells)
    profileExtra = ''
      # mise tool version manager - add shims to PATH
      export PATH="$HOME/.local/share/mise/shims:$PATH"

      # Set BASH_ENV so non-interactive bash shells (like make) can find mise
      export BASH_ENV="$HOME/.bash_env"

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # Rancher Desktop
      [ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"
    '';
  };
}
