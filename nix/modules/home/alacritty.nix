# Alacritty terminal configuration
#
# Migrated from chezmoi TOML config to home-manager.
# Uses programs.alacritty for declarative configuration.
{ config, lib, pkgs, ... }:

{
  programs.alacritty = {
    enable = true;

    settings = {
      debug = {
        log_level = "Debug";
        print_events = false;
        render_timer = false;
      };

      font = {
        size = 20.0;
        normal = {
          family = "FiraCode Nerd Font Mono";
        };
      };

      scrolling = {
        history = 5000;
        multiplier = 3;
      };

      terminal.shell = {
        program = "/opt/homebrew/bin/fish";
        args = [ "--command" "tmuxp load dev" ];
      };

      window = {
        startup_mode = "Fullscreen";
        option_as_alt = "Both";
        decorations = "buttonless";
      };

      bell = {
        animation = "Linear";
        duration = 0;
        color = "#000000";
      };

      # Make Shift+Enter work for Claude Code running in tmux panes
      keyboard.bindings = [
        {
          key = "Return";
          mods = "Shift";
          chars = "\n";
        }
      ];
    };
  };
}
