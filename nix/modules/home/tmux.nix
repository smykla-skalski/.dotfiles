# Tmux configuration
#
# Uses programs.tmux with TPM (Tmux Plugin Manager) for plugins.
{ config, lib, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    shell = "${pkgs.fish}/bin/fish";

    # Enable tmuxp session manager
    tmuxp.enable = true;

    # Prefix key: Ctrl+a
    prefix = "C-a";
    shortcut = "a";

    # Settings
    baseIndex = 1;
    escapeTime = 1;
    historyLimit = 5000;
    mouse = true;
    keyMode = "vi";
    terminal = "alacritty";

    # TPM plugins
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
    ];

    extraConfig = ''
      # Resurrect settings
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-capture-pane-contents 'on'

      # Ensure we can send 'Ctrl+a' to other apps
      bind C-a send-prefix

      # Force reload of config file
      unbind r
      bind r source-file ~/.config/tmux/tmux.conf\; display "Reloaded tmux.conf"

      # Bind key X to kill pane without confirmation prompt
      bind X kill-pane

      # Splitting panes with '|' and '-' with the same path as the current pane
      bind | split-window -h -c "#{pane_current_path}"
      bind - split-window -v -c "#{pane_current_path}"

      # When creating new window, use path from current pane
      bind c new-window -c "#{pane_current_path}"

      # Start pane numbering at 1 instead of 0
      set -g pane-base-index 1

      # Remove default layout switching on Prefix + Alt + number
      unbind-key -T prefix -q M-1
      unbind-key -T prefix -q M-2
      unbind-key -T prefix -q M-3
      unbind-key -T prefix -q M-4
      unbind-key -T prefix -q M-5

      # Jump to pane by number with Alt-{1-9}
      bind -n M-1 select-pane -t :.1
      bind -n M-2 select-pane -t :.2
      bind -n M-3 select-pane -t :.3
      bind -n M-4 select-pane -t :.4
      bind -n M-5 select-pane -t :.5
      bind -n M-6 select-pane -t :.6
      bind -n M-7 select-pane -t :.7
      bind -n M-8 select-pane -t :.8
      bind -n M-9 select-pane -t :.9

      bind n next-window
      bind p previous-window

      # Disable arrow key pane navigation
      unbind Up
      unbind Down
      unbind Left
      unbind Right

      # Quick pane resizing
      bind -r H resize-pane -L 5
      bind -r J resize-pane -D 5
      bind -r K resize-pane -U 5
      bind -r L resize-pane -R 5

      # Alacritty terminal features
      set -as terminal-features ",alacritty:RGB"

      set -g status-interval 5
      set -g display-time 750

      # Colors
      set -g status-style fg=white,bg=black
      set -g window-status-style fg=white,bg=default
      set -g window-status-current-style fg=cyan,bold,bg=default
      set -g message-style fg=white,bold,bg=black

      # Pane border (green when active, white otherwise)
      set -g pane-border-format "#{?pane_active,#[fg=green],#[fg=white]}#[align=right,bold] #P "
      set -g pane-border-status bottom

      # Status line
      set -g status-left-length 40
      set -g status-left "#[fg=colour240][#S] "
      set -g status-right "#[fg=colour242]%d/%B/%Y #[fg=white]%R"

      # Unbind default behavior of Ctrl-d (detaching session without prefix)
      unbind -n C-d

      # Clear pane and history (scroll buffer)
      bind-key C-d send-keys C-l \; run 'sleep 0' \; clear-history
    '';
  };
}
