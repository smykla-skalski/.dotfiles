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
  # macOS uses ~/Library/Application Support instead of ~/.config
  # Gocheat format: { items: [...], styles: {...} }
  # Each item: { tag: "...", title: "description : keybind" }
  home.file."Library/Application Support/gocheat/config.json".text = builtins.toJSON {
    items = [
      # Navigation - NEW Shortcuts
      {
        tag = "nav-new";
        title = "Vim-style line down/up [NEW] : Ctrl-j / Ctrl-k";
      }
      {
        tag = "nav-new";
        title = "Vim-style page down/up [NEW] : Ctrl-d / Ctrl-u";
      }
      {
        tag = "nav-new";
        title = "Go to parent directory [NEW] : Ctrl-p";
      }
      {
        tag = "nav-new";
        title = "Go to home directory [NEW] : Ctrl-home";
      }

      # Navigation - Classic
      {
        tag = "nav";
        title = "Navigate up/down tree : ↑ / ↓";
      }
      {
        tag = "nav";
        title = "Open directory or file : Enter";
      }
      {
        tag = "nav";
        title = "Back/cancel action : Esc";
      }
      {
        tag = "nav";
        title = "Cycle through matches : Tab";
      }

      # File Operations
      {
        tag = "files";
        title = "Edit file in $EDITOR : e or Ctrl-e";
      }
      {
        tag = "files-new";
        title = "Create new directory [NEW] : :md <name>";
      }
      {
        tag = "files";
        title = "Create and edit new file : :create <path>";
      }
      {
        tag = "files";
        title = "Backup file with version : Ctrl-b";
      }
      {
        tag = "files";
        title = "Delete file/directory : :rm";
      }
      {
        tag = "files";
        title = "Copy file/directory : :cp <dest>";
      }
      {
        tag = "files";
        title = "Move/rename file : :mv <dest>";
      }

      # Panel Operations - NEW Norton Commander Style
      {
        tag = "panel-new";
        title = "Copy to other panel (Norton) [NEW] : F5";
      }
      {
        tag = "panel-new";
        title = "Move to other panel (Norton) [NEW] : F6";
      }
      {
        tag = "panel";
        title = "Open panel/preview : Ctrl-→";
      }
      {
        tag = "panel";
        title = "Close panel/go back : Ctrl-←";
      }

      # Git Operations - NEW Shortcuts
      {
        tag = "git-new";
        title = "Git status interactive [NEW] : gs";
      }
      {
        tag = "git-new";
        title = "Go to git root [NEW] : gtr";
      }
      {
        tag = "git-new";
        title = "Toggle git status filter [NEW] : Alt-g";
      }
      {
        tag = "git";
        title = "Git diff current file : gd";
      }
      {
        tag = "git";
        title = "Stage file (built-in) : Ctrl-g";
      }

      # Search & Filter
      {
        tag = "search";
        title = "Fuzzy search (just type!) : <pattern>";
      }
      {
        tag = "search-new";
        title = "Total search (large dirs) [NEW] : Ctrl-s";
      }
      {
        tag = "search";
        title = "Regex search : /<pattern>";
      }
      {
        tag = "search";
        title = "Search file content : c/<pattern>";
      }

      # Toggles
      {
        tag = "toggle";
        title = "Toggle gitignored files : Alt-i";
      }
      {
        tag = "toggle";
        title = "Toggle hidden files : Alt-h";
      }
      {
        tag = "toggle";
        title = "Show/hide file sizes : :toggle_sizes";
      }
      {
        tag = "toggle";
        title = "Show/hide permissions : :toggle_perm";
      }

      # Miscellaneous
      {
        tag = "misc";
        title = "Show help (MASTER KEY!) : ?";
      }
      {
        tag = "misc-new";
        title = "Reveal in Finder (macOS) [NEW] : r";
      }
      {
        tag = "misc";
        title = "Launch terminal here : Ctrl-t";
      }
      {
        tag = "misc";
        title = "CD to dir and exit : Alt-Enter";
      }
      {
        tag = "misc";
        title = "Exit broot : Ctrl-c";
      }
    ];

    # Monokai color scheme
    # Gocheat only supports 'accent' (keybinds) and 'subtext' (descriptions)
    styles = {
      accent = "#66d9ef";      # Monokai cyan for keybinds
      subtext = "#a6e22e";     # Monokai green for descriptions
    };
  };

  # Optional: Add Fish abbreviation for quick access
  programs.fish.shellAbbrs = lib.mkIf config.programs.fish.enable {
    bk = "gocheat";  # Quick cheatsheet access
  };
}
