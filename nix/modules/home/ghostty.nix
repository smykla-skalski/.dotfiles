# Ghostty terminal configuration
#
# Ghostty is a fast, feature-rich terminal emulator with native macOS UI.
# Package installed via Homebrew (Nix package broken on Darwin).
# This module manages configuration only.
{ config, lib, pkgs, ... }:

let
  fishPath = "${pkgs.fish}/bin/fish";
  tmuxPath = "${pkgs.tmux}/bin/tmux";
  tmuxpPath = "${pkgs.tmuxp}/bin/tmuxp";
  ghosttyTmuxLauncher = pkgs.writeShellScript "ghostty-tmux-launcher" ''
    set -eu

    start_tmux() {
      if ${tmuxPath} has-session -t main 2>/dev/null; then
        ${tmuxPath} attach-session -t main
        return $?
      fi

      if [ -x "${tmuxpPath}" ]; then
        if "${tmuxpPath}" load -d dev >/dev/null 2>&1; then
          ${tmuxPath} attach-session -t main
          return $?
        fi
      fi

      ${tmuxPath} new-session -A -s main
    }

    if [ -z "''${PWD-}" ]; then
      export PWD="$HOME"
    fi

    if [ -n "''${TMUX-}" ]; then
      exec ${fishPath}
    fi

    if start_tmux; then
      exit 0
    fi

    # Fallback path if xterm-ghostty terminfo is unavailable for tmux.
    if [ "''${TERM-}" = "xterm-ghostty" ]; then
      export TERM=xterm-256color
      if start_tmux; then
        exit 0
      fi
    fi

    # Last resort: keep terminal usable even if tmux startup fails.
    exec ${fishPath}
  '';
in
{
  programs.ghostty = {
    enable = true;

    # Don't install via Nix - package broken on Darwin, use Homebrew cask instead
    package = null;

    # Fish shell integration for proper terminfo
    enableFishIntegration = true;

    settings = {
      # Font configuration
      font-family = "FiraCode Nerd Font Mono";
      font-size = 15;
      font-thicken = true;

      # Window configuration
      window-decoration = "auto";
      macos-option-as-alt = true;
      macos-titlebar-style = "hidden";
      window-show-tab-bar = "never";

      # Start in fullscreen (like Alacritty config)
      fullscreen = true;

      # Scrollback
      scrollback-limit = 10000;

      # Keep Ghostty terminal identity for app feature detection.
      term = "xterm-ghostty";

      # Always launch into shared tmux session
      command = "direct:${ghosttyTmuxLauncher}";

      # Shell integration (title needed for fish_title to work)
      shell-integration-features = "cursor,sudo,title";

      # Quick Terminal (drop-down from top)
      quick-terminal-position = "top";
      quick-terminal-animation-duration = "0.1";

      # Cursor
      cursor-style = "block";
      cursor-style-blink = false;

      # Copy/paste behavior
      copy-on-select = "clipboard";
      clipboard-paste-protection = false;
      clipboard-trim-trailing-spaces = true;

      # Keep Shift reserved for Ghostty so Cmd+Shift+Click still opens URLs
      # when tmux or another TUI has mouse reporting enabled.
      link-url = true;
      mouse-shift-capture = "never";

      # Always confirm before closing (protects against accidental Cmd+Q)
      confirm-close-surface = "always";

      # Aesthetics
      background-opacity = 0.95;

      # Unfocused split configuration
      # Moderate dimming with subtle color tint for better distinction
      unfocused-split-opacity = 0.65;
      unfocused-split-fill = "#1a1a1a";

      # Bright, visible divider (coral/salmon pink from terminal)
      split-divider-color = "#E06C75";

      # Performance
      adjust-cell-width = 0;

      # Theme
      theme = "Monokai Classic";

      # Optional local config overlay (writable, for runtime modifications like font-size)
      # Hammerspoon can modify this file to override settings without touching Nix config
      config-file = "?~/.config/ghostty/config.local";

      # Keybindings - Using standard terminal shortcuts (iTerm2/Terminal.app style)
      keybind = [
        # Shift+Enter sends newline (for Claude Code)
        "shift+enter=text:\\n"

        # Quick Terminal global hotkey (requires Accessibility permission)
        "global:cmd+alt+grave_accent=toggle_quick_terminal"

        # Inspector for debugging keybindings
        "super+i=inspector:toggle"

        # === Tmux-first pane workflow ===
        # Create panes
        "cmd+d=text:\\x01|"
        "cmd+shift+d=text:\\x01-"
        "cmd+alt+z=text:\\x01z"

        # Navigate panes
        "cmd+alt+left=text:\\x01h"
        "cmd+alt+right=text:\\x01l"
        "cmd+alt+up=text:\\x01k"
        "cmd+alt+down=text:\\x01j"

        # Keep these for Ghostty split cycling used by Hammerspoon
        "cmd+bracket_left=goto_split:previous"     # Cmd+[
        "cmd+bracket_right=goto_split:next"        # Cmd+]

        # Resize panes
        "cmd+ctrl+left=text:\\x01H"
        "cmd+ctrl+right=text:\\x01L"
        "cmd+ctrl+up=text:\\x01K"
        "cmd+ctrl+down=text:\\x01J"
        "cmd+shift+equal=text:\\x01="

        # === Tmux windows ===
        "cmd+t=text:\\x01c"
        "cmd+w=text:\\x01X"

        # Window navigation
        "cmd+one=text:\\x011"
        "cmd+two=text:\\x012"
        "cmd+three=text:\\x013"
        "cmd+four=text:\\x014"
        "cmd+five=text:\\x015"
        "cmd+six=text:\\x016"
        "cmd+seven=text:\\x017"
        "cmd+eight=text:\\x018"
        "cmd+nine=text:\\x019"
        "cmd+shift+bracket_left=text:\\x01p"
        "cmd+shift+bracket_right=text:\\x01n"
        "cmd+grave_accent=text:\\x01n"
        "cmd+shift+grave_accent=text:\\x01p"

        # === Utility shortcuts ===
        "cmd+k=clear_screen"                       # Clear screen (Terminal.app standard)
        "cmd+shift+k=clear_screen"                 # Alternative clear
        "cmd+r=reload_config"                      # Reload config

        # Shell integration - jump between prompts
        "ctrl+shift+up=jump_to_prompt:-1"
        "ctrl+shift+down=jump_to_prompt:1"
      ];
    };
  };
}
