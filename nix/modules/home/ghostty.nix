# Ghostty terminal configuration
#
# Ghostty is a fast, feature-rich terminal emulator with native macOS UI.
# Package installed via Homebrew (Nix package broken on Darwin).
# This module manages configuration only.
{ config, lib, pkgs, ... }:

let
  fishPath = "${pkgs.fish}/bin/fish";
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
      macos-titlebar-style = "tabs";
      window-show-tab-bar = "auto";

      # Start in fullscreen (like Alacritty config)
      fullscreen = true;

      # Scrollback
      scrollback-limit = 10000;

      # Shell - just fish, no tmux
      command = fishPath;

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

      # Always confirm before closing (protects against accidental Cmd+Q)
      confirm-close-surface = "always";

      # Aesthetics
      background-opacity = 0.95;
      unfocused-split-opacity = 0.5;
      unfocused-split-fill = "#000000";

      # Performance
      adjust-cell-width = 0;

      # Theme
      theme = "Monokai Classic";

      # Keybindings (list format required for duplicate keys)
      # Using Ctrl+a as prefix (tmux-like)
      keybind = [
        # Shift+Enter sends newline (for Claude Code)
        "shift+enter=text:\\n"

        # Quick Terminal global hotkey (requires Accessibility permission)
        "global:cmd+grave_accent=toggle_quick_terminal"

        # Inspector for debugging keybindings
        "super+i=inspector:toggle"

        # Splits (tmux-like: Ctrl+a then | or -)
        # Try shift+backslash explicitly (should produce |)
        "ctrl+a>shift+backslash=new_split:right"
        # Also keep v/s as fallback
        "ctrl+a>v=new_split:right"
        "ctrl+a>s=new_split:down"
        # Horizontal split with -
        "ctrl+a>-=new_split:down"
        "ctrl+a>z=toggle_split_zoom"

        # Navigate splits (tmux-like: Ctrl+a then h/j/k/l)
        "ctrl+a>h=goto_split:left"
        "ctrl+a>l=goto_split:right"
        "ctrl+a>j=goto_split:down"
        "ctrl+a>k=goto_split:up"

        # Resize splits (Ctrl+a then H/J/K/L)
        "ctrl+a>shift+h=resize_split:left,50"
        "ctrl+a>shift+l=resize_split:right,50"
        "ctrl+a>shift+j=resize_split:down,50"
        "ctrl+a>shift+k=resize_split:up,50"

        # Tabs (tmux-like)
        "ctrl+a>c=new_tab"
        "ctrl+a>n=next_tab"
        "ctrl+a>p=previous_tab"
        "ctrl+a>w=close_surface"

        # Reload config (tmux-like)
        "ctrl+a>r=reload_config"

        # Jump to tab by number (Alt+1-9 like current tmux)
        "alt+one=goto_tab:1"
        "alt+two=goto_tab:2"
        "alt+three=goto_tab:3"
        "alt+four=goto_tab:4"
        "alt+five=goto_tab:5"
        "alt+six=goto_tab:6"
        "alt+seven=goto_tab:7"
        "alt+eight=goto_tab:8"
        "alt+nine=goto_tab:9"

        # Alternative tab navigation
        "cmd+shift+right=next_tab"
        "cmd+shift+left=previous_tab"

        # Shell integration - jump between prompts
        "ctrl+shift+up=jump_to_prompt:-1"
        "ctrl+shift+down=jump_to_prompt:1"

        # Clear screen (ctrl+a then x)
        "ctrl+a>x=clear_screen"

        # Equalize splits (ctrl+a then e)
        "ctrl+a>e=equalize_splits"
      ];
    };
  };
}
