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

        # === Splits (standard shortcuts) ===
        # Create splits
        "cmd+d=new_split:right"                    # Vertical split (like iTerm2)
        "cmd+shift+d=new_split:down"               # Horizontal split (like iTerm2)
        "cmd+alt+z=toggle_split_zoom"              # Toggle zoom current split

        # Navigate splits
        "cmd+alt+left=goto_split:left"
        "cmd+alt+right=goto_split:right"
        "cmd+alt+up=goto_split:up"
        "cmd+alt+down=goto_split:down"
        "cmd+bracket_left=goto_split:previous"     # Cmd+[
        "cmd+bracket_right=goto_split:next"        # Cmd+]

        # Resize splits
        "cmd+ctrl+left=resize_split:left,50"
        "cmd+ctrl+right=resize_split:right,50"
        "cmd+ctrl+up=resize_split:up,50"
        "cmd+ctrl+down=resize_split:down,50"
        "cmd+shift+equal=equalize_splits"          # Cmd+Shift+= (like Cmd++)

        # === Tabs (standard shortcuts) ===
        "cmd+t=new_tab"                            # New tab (universal)
        "cmd+w=close_surface"                      # Close tab/split (universal)

        # Navigate tabs with Cmd+number
        "cmd+one=goto_tab:1"
        "cmd+two=goto_tab:2"
        "cmd+three=goto_tab:3"
        "cmd+four=goto_tab:4"
        "cmd+five=goto_tab:5"
        "cmd+six=goto_tab:6"
        "cmd+seven=goto_tab:7"
        "cmd+eight=goto_tab:8"
        "cmd+nine=goto_tab:9"

        # Also support Alt+number for tab navigation (alternative)
        "alt+one=goto_tab:1"
        "alt+two=goto_tab:2"
        "alt+three=goto_tab:3"
        "alt+four=goto_tab:4"
        "alt+five=goto_tab:5"
        "alt+six=goto_tab:6"
        "alt+seven=goto_tab:7"
        "alt+eight=goto_tab:8"
        "alt+nine=goto_tab:9"

        # Tab navigation with arrows
        "cmd+shift+bracket_left=previous_tab"      # Cmd+Shift+[
        "cmd+shift+bracket_right=next_tab"         # Cmd+Shift+]
        "cmd+grave_accent=next_tab"                # Cmd+~ (backtick)
        "cmd+shift+grave_accent=previous_tab"      # Cmd+Shift+~

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
