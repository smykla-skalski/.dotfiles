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
      # Prevent "unbound variable" errors in strict mode (set -u)
      # PROMPT_COMMAND is typically set by interactive shells but not in non-interactive mode
      : "''${PROMPT_COMMAND:=}"

      # Suppress pkg_resources deprecation warning from kathara_lab_checker
      export PYTHONWARNINGS="ignore::UserWarning"

      # Claude Code skills CLI wrapper
      export PATH="$HOME/Projects/github.com/smykla-skalski/research/claude-code/skills/_bin:$PATH"

      # klab - Kubernetes networking labs
      export PATH="$HOME/Projects/github.com/smykla-skalski/klab/.bin:$PATH"

      # Python shell.nix location for direnv
      export DOTFILES_PATH="$HOME/Projects/github.com/smykla-skalski/.dotfiles"
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

      # Fish abbreviation-tips exports are shell-local UI config. Keep them out
      # of non-Fish processes so toolchains do not inherit malformed prompt bytes.
      unset ABBR_TIPS_PROMPT ABBR_TIPS_REGEXES ABBR_TIPS_AUTO_UPDATE
    '';

    # .zshrc content (interactive shells only)
    initContent = ''
      # fzf integration
      [ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

      # Activate mise for interactive shells (prompt hook re-evaluates on cd)
      if command -v mise >/dev/null 2>&1; then
        eval "$(mise activate zsh)"
      fi

      # opencode completion (yargs-generated bash completion loaded via bashcompinit)
      if command -v opencode >/dev/null 2>&1; then
        autoload -U bashcompinit
        bashcompinit
        eval "$(opencode completion)"
      fi
    '';
  };
}
