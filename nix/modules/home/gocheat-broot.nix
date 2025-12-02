# Gocheat configuration for Broot shortcuts
#
# Installation:
#   1. Copy this file to nix/modules/home/gocheat-broot.nix
#   2. Import in your home.nix: imports = [ ./gocheat-broot.nix ];
#   3. Run: home-manager switch
#
# Usage:
#   - Launch gocheat: gocheat
#   - Add Fish abbr: abbr -a bk gocheat
#   - Bind to terminal key (e.g., Ctrl-Alt-b)

{ config, lib, pkgs, ... }:

{
  # Install gocheat package
  home.packages = with pkgs; [
    gocheat
  ];

  # Configure gocheat with broot shortcuts
  xdg.configFile."gocheat/config.json".text = builtins.toJSON {
    description = "Broot Keyboard Shortcuts - Focus on NEW shortcuts";
    entries = [
      # Navigation - NEW Shortcuts
      {
        tag = "nav-new";
        keybind = "Ctrl-j / Ctrl-k";
        description = "Vim-style line down/up [NEW]";
      }
      {
        tag = "nav-new";
        keybind = "Ctrl-d / Ctrl-u";
        description = "Vim-style page down/up [NEW]";
      }
      {
        tag = "nav-new";
        keybind = "Ctrl-p";
        description = "Go to parent directory [NEW]";
      }
      {
        tag = "nav-new";
        keybind = "Ctrl-home";
        description = "Go to home directory [NEW]";
      }

      # Navigation - Classic
      {
        tag = "nav";
        keybind = "↑ / ↓";
        description = "Navigate up/down tree";
      }
      {
        tag = "nav";
        keybind = "Enter";
        description = "Open directory or file";
      }
      {
        tag = "nav";
        keybind = "Esc";
        description = "Back/cancel action";
      }
      {
        tag = "nav";
        keybind = "Tab";
        description = "Cycle through matches";
      }

      # File Operations
      {
        tag = "files";
        keybind = "e or Ctrl-e";
        description = "Edit file in $EDITOR";
      }
      {
        tag = "files-new";
        keybind = ":md <name>";
        description = "Create new directory [NEW]";
      }
      {
        tag = "files";
        keybind = ":create <path>";
        description = "Create and edit new file";
      }
      {
        tag = "files";
        keybind = "Ctrl-b";
        description = "Backup file with version";
      }
      {
        tag = "files";
        keybind = ":rm";
        description = "Delete file/directory";
      }
      {
        tag = "files";
        keybind = ":cp <dest>";
        description = "Copy file/directory";
      }
      {
        tag = "files";
        keybind = ":mv <dest>";
        description = "Move/rename file";
      }

      # Panel Operations - NEW Norton Commander Style
      {
        tag = "panel-new";
        keybind = "F5";
        description = "Copy to other panel (Norton) [NEW]";
      }
      {
        tag = "panel-new";
        keybind = "F6";
        description = "Move to other panel (Norton) [NEW]";
      }
      {
        tag = "panel";
        keybind = "Ctrl-→";
        description = "Open panel/preview";
      }
      {
        tag = "panel";
        keybind = "Ctrl-←";
        description = "Close panel/go back";
      }

      # Git Operations - NEW Shortcuts
      {
        tag = "git-new";
        keybind = "gs";
        description = "Git status interactive [NEW]";
      }
      {
        tag = "git-new";
        keybind = "gtr";
        description = "Go to git root [NEW]";
      }
      {
        tag = "git-new";
        keybind = "Alt-g";
        description = "Toggle git status filter [NEW]";
      }
      {
        tag = "git";
        keybind = "gd";
        description = "Git diff current file";
      }
      {
        tag = "git";
        keybind = "Ctrl-g";
        description = "Stage file (built-in)";
      }

      # Search & Filter
      {
        tag = "search";
        keybind = "<pattern>";
        description = "Fuzzy search (just type!)";
      }
      {
        tag = "search-new";
        keybind = "Ctrl-s";
        description = "Total search (large dirs) [NEW]";
      }
      {
        tag = "search";
        keybind = "/<pattern>";
        description = "Regex search";
      }
      {
        tag = "search";
        keybind = "c/<pattern>";
        description = "Search file content";
      }

      # Toggles
      {
        tag = "toggle";
        keybind = "Alt-i";
        description = "Toggle gitignored files";
      }
      {
        tag = "toggle";
        keybind = "Alt-h";
        description = "Toggle hidden files";
      }
      {
        tag = "toggle";
        keybind = ":toggle_sizes";
        description = "Show/hide file sizes";
      }
      {
        tag = "toggle";
        keybind = ":toggle_perm";
        description = "Show/hide permissions";
      }

      # Miscellaneous
      {
        tag = "misc";
        keybind = "?";
        description = "Show help (MASTER KEY!)";
      }
      {
        tag = "misc-new";
        keybind = "r";
        description = "Reveal in Finder (macOS) [NEW]";
      }
      {
        tag = "misc";
        keybind = "Ctrl-t";
        description = "Launch terminal here";
      }
      {
        tag = "misc";
        keybind = "Alt-Enter";
        description = "CD to dir and exit";
      }
      {
        tag = "misc";
        keybind = "Ctrl-c";
        description = "Exit broot";
      }
    ];

    # Catppuccin-inspired color scheme (dark blue theme)
    styles = {
      description_color = "#82aaff";  # Light blue
      keybind_color = "#c3e88d";      # Green
      tag_color = "#ffcb6b";          # Yellow
      border_color = "#717cb4";       # Purple-ish
    };
  };

  # Optional: Add Fish abbreviation for quick access
  programs.fish.shellAbbrs = lib.mkIf config.programs.fish.enable {
    bk = "gocheat";  # Quick cheatsheet access
  };
}
