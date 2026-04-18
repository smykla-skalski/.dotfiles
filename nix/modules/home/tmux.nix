# Tmux configuration
#
# Uses programs.tmux with TPM (Tmux Plugin Manager) for plugins.
{ config, lib, pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    # Use the profile symlink instead of a store-pinned fish path so long-lived
    # tmux servers keep opening panes with the current shell generation.
    shell = "${config.home.homeDirectory}/.nix-profile/bin/fish";

    # Enable tmuxp session manager
    tmuxp.enable = true;

    # Prefix key: Ctrl+a
    prefix = "C-a";
    shortcut = "a";

    # Settings
    baseIndex = 1;
    escapeTime = 1;
    focusEvents = true;
    historyLimit = 5000;
    mouse = true;
    keyMode = "vi";
    terminal = "tmux-256color";

    # TPM plugins
    plugins = with pkgs.tmuxPlugins; [
      sensible
      resurrect
    ];

    extraConfig = ''
      # Ghostty can launch tmux with a stripped PATH that omits the Nix profile.
      # Set the server environment explicitly so run-shell hooks and TPM plugins
      # can always find tmux and other profile-managed binaries.
      set-environment -g PATH "${config.home.homeDirectory}/.nix-profile/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
      set-environment -g SHELL "${config.home.homeDirectory}/.nix-profile/bin/fish"

      # Resurrect settings
      set -g @resurrect-strategy-vim 'session'
      set -g @resurrect-capture-pane-contents 'on'

      # Ghostty terminal features
      set -as terminal-features ',xterm-ghostty:RGB:clipboard:hyperlinks:osc7:strikethrough:overline:usstyle:sync:extkeys'
      set -as terminal-features ',xterm-256color:RGB:clipboard:hyperlinks:osc7:strikethrough:overline:usstyle:sync:extkeys'

      # Avoid passthrough rendering glitches in OpenCode + tmux
      set -g allow-passthrough off

      # Require Ctrl for mouse pane resize to prevent accidental resizing
      # when dragging (e.g. scrollbar) crosses a pane border
      unbind -T root MouseDrag1Border
      bind -T root C-MouseDrag1Border resize-pane -M

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

      # Equalize panes
      bind = select-layout tiled

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

      # Pane navigation
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

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

      # Window naming: use process name, fall back to dir basename at shell prompt
      set-option -g automatic-rename on
      set-option -g automatic-rename-format '#{?#{==:#{pane_current_command},fish},#{b:pane_current_path},#{s/^codex-[^ ]*$/codex/:#{s/^[0-9][0-9.]*$/claude/:#{pane_current_command}}}}'
      # Prevent CLI tools from overriding the window name with version strings
      set-option -g allow-rename off
      # Push the window name to Ghostty's tab title
      set-option -g set-titles on
      set-option -g set-titles-string '#W [#S]'

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
