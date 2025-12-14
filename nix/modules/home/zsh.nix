# Zsh shell configuration
#
# Configures zsh to support aliases in both interactive and non-interactive shells.
# This is needed for Claude Code which uses zsh for its built-in shell.
{ config, lib, pkgs, ... }:

{
  programs.zsh = {
    enable = true;

    # .zshenv is sourced for ALL zsh shells (interactive, non-interactive, login, etc.)
    # This is perfect for Claude Code's non-interactive shells
    envExtra = ''
      # Add ~/.local/bin to PATH for mise executable
      export PATH="$HOME/.local/bin:$PATH"

      # Python shell.nix location for direnv
      export DOTFILES_PATH="$HOME/Projects/github.com/smykla-labs/.dotfiles"
      export PYTHON_SHELL_NIX="$DOTFILES_PATH/nix/python-env/shell.nix"

      # Cargo environment
      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      # Rancher Desktop
      [ -d "$HOME/.rd/bin" ] && export PATH="$HOME/.rd/bin:$PATH"

      # For non-interactive shells, use mise hook-env
      if command -v mise >/dev/null 2>&1; then
          eval "$(mise hook-env -s zsh)"
      fi

      # Source shared shell functions (from Fish functions)
      [ -f "$HOME/.config/shell/functions.sh" ] && source "$HOME/.config/shell/functions.sh"

      # Source shared shell aliases (from Fish abbreviations)
      [ -f "$HOME/.config/shell/aliases.sh" ] && source "$HOME/.config/shell/aliases.sh"
    '';

    # .zshrc content (interactive shells only)
    initContent = ''
      # fzf integration
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
    '';
  };
}
