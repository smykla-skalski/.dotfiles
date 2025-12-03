# Bash shell configuration
#
# Migrated from chezmoi to home-manager programs.bash.
# Configures .bashrc and .profile for non-interactive and login shell scenarios.
{ config, lib, pkgs, ... }:

{
  programs.bash = {
    enable = true;

    # .bashrc content (interactive shells)
    initExtra = ''
      # Add ~/.local/bin to PATH for mise and other tools
      export PATH="$HOME/.local/bin:$PATH"

      # Set BASH_ENV for non-interactive subshells (needed by make)
      export BASH_ENV="$HOME/.bash_env"

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

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # Rancher Desktop
      [ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"
    '';
  };
}
