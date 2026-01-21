# Fish shell environment configuration
# Includes environment variables, PATH setup, and tool integrations
{ config, ... }:

{
  programs.fish.interactiveShellInit = ''
    # Disable initial welcome message
    set --global fish_greeting

    # Fish color theme (syntax highlighting)
    set --global fish_color_autosuggestion brblack
    set --global fish_color_cancel -r
    set --global fish_color_command normal
    set --global fish_color_comment red
    set --global fish_color_cwd green
    set --global fish_color_cwd_root red
    set --global fish_color_end green
    set --global fish_color_error brred
    set --global fish_color_escape brcyan
    set --global fish_color_history_current --bold
    set --global fish_color_host normal
    set --global fish_color_host_remote yellow
    set --global fish_color_normal normal
    set --global fish_color_operator brcyan
    set --global fish_color_param cyan
    set --global fish_color_quote yellow
    set --global fish_color_redirection cyan --bold
    set --global fish_color_search_match white --background=brblack
    set --global fish_color_selection white --bold --background=brblack
    set --global fish_color_status red
    set --global fish_color_user brgreen
    set --global fish_color_valid_path --underline
    set --global fish_pager_color_completion normal
    set --global fish_pager_color_description yellow -i
    set --global fish_pager_color_prefix normal --bold --underline
    set --global fish_pager_color_progress brwhite --background=cyan
    set --global fish_pager_color_selected_background -r

    # Environment variables
    set --export PROJECTS_PATH $HOME/Projects/github.com
    set --export MY_PROJECTS_PATH $PROJECTS_PATH/bartsmykla
    set --export DOTFILES_PATH $PROJECTS_PATH/smykla-labs/.dotfiles
    set --export FORTRESS_PATH /Volumes/fortress-carima
    set --export SECRETS_PATH $DOTFILES_PATH/secrets
    set --export PYTHON_SHELL_NIX $DOTFILES_PATH/nix/python-env/shell.nix
    set --export EDITOR vim
    set --export LC_ALL en_US.UTF-8
    set --export LANG en_US.UTF-8
    set --export SHELL $HOME/.nix-profile/bin/bash
    set --export BASH_ENV $HOME/.bash_env

    # fzf configuration (fzf 0.67.0+)
    # These are set here instead of _fzf_wrapper.fish for more control
    # See: https://github.com/junegunn/fzf#environment-variables
    set --export FZF_DEFAULT_OPTS "\
      --cycle \
      --layout=reverse \
      --border=rounded \
      --height=90% \
      --preview-window=wrap \
      --marker='*' \
      --highlight-line \
      --info=inline-right \
      --tmux=bottom,50% \
      --color=fg:#f8f8f2,bg:#272822,hl:#66d9ef \
      --color=fg+:#f8f8f2,bg+:#3e3d32,hl+:#66d9ef \
      --color=info:#a6e22e,prompt:#f92672,pointer:#ae81ff \
      --color=marker:#a6e22e,spinner:#ae81ff,header:#75715e \
      --color=bg+:-1,gutter:-1 \
      --bind='ctrl-/:toggle-preview'"

    # fzf shell integration options
    # CTRL-T: File search with bat preview and syntax highlighting
    set --export FZF_CTRL_T_OPTS "\
      --walker-skip .git,node_modules,target \
      --preview 'bat --style=numbers --color=always --line-range :500 {}' \
      --bind 'ctrl-/:change-preview-window(down|hidden|)'"

    # ALT-C: Directory navigation with eza/tree preview
    set --export FZF_ALT_C_OPTS "\
      --preview 'eza --all --long --icons always --tree --level=2 --color=always {} 2>/dev/null || tree -C -L 2 {} 2>/dev/null || ls -A -F {}'"

    # fzf.fish history-specific options
    # Better time format showing relative day if recent
    set --global fzf_history_time_format "%Y-%m-%d %H:%M"
    # Additional history options (appended to defaults)
    set --global fzf_history_opts "--no-sort"

    # fzf.fish directory preview customization
    # Use eza for better directory listings with icons and colors
    set --global fzf_preview_dir_cmd "eza --all --long --icons always --color=always"

    # Homebrew (skip if already initialized to speed up subshells)
    if not set -q HOMEBREW_PREFIX
      /opt/homebrew/bin/brew shellenv fish | source
    end

    # PATH additions
    fish_add_path --global --move $FORTRESS_PATH/.dotfiles/bin
    fish_add_path --global --move "$HOME/.cargo/bin"
    fish_add_path --global --move "$HOME/.local/bin"
    fish_add_path --global --move "$HOME/bin"
    fish_add_path --global --move "$HOMEBREW_PREFIX/opt/coreutils/libexec/gnubin"
    fish_add_path --global --append "$HOME/.krew/bin"
    fish_add_path --global --append "$HOME/.opencode/bin"
    fish_add_path --global --append "$PROJECTS_PATH/smykla-labs/research/claude-code/skills/_bin"

    # mise tool completions (auto-generated)
    if test -f "$DOTFILES_PATH/tmp/mise-completions.fish"
      source "$DOTFILES_PATH/tmp/mise-completions.fish"
    end

    # ansible config
    set --global --export ANSIBLE_CONFIG "$DOTFILES_PATH/ansible/ansible.cfg"

    # gcloud cli tool
    set --global --export USE_GKE_GCLOUD_AUTH_PLUGIN "True"
    if test -f "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.fish.inc"
      source "$HOMEBREW_PREFIX/share/google-cloud-sdk/path.fish.inc"
    end

    # Note: Direnv hook handled by programs.direnv in direnv.nix
    # Manual hook disabled since direnv.nix handles integration
    set --global direnv_fish_mode eval_on_arrow

    # Note: Starship initialization handled by programs.starship in starship.nix
    # Manual initialization disabled since starship.nix enableFishIntegration=true handles it

    # jump (autojump alternative)
    if command -q jump
      jump shell fish | source
    end

    # 1password SSH agent
    set --global --export SSH_AUTH_SOCK "$HOME/.1password/agent.sock"

    # teleport (doesn't work well with 1password SSH agent)
    set --global --export TELEPORT_USE_LOCAL_SSH_AGENT false

    # Source secrets from SECRETS_PATH directory
    for secret in $SECRETS_PATH/*
      if test -f $secret
        eval "set -gx (basename $secret) (cat $secret)"
      end
    end
  '';
}
