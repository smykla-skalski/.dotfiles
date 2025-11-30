# Tmuxp session manager configuration
#
# Migrated from chezmoi to home-manager.
# Tmuxp is a session manager for tmux that uses YAML configs.
#
# Note: programs.tmux.tmuxp.enable is already available in home-manager,
# this module handles the session configuration files.
{ config, lib, pkgs, ... }:

{
  # Tmuxp session configurations
  xdg.configFile."tmuxp/dev.yaml".text = ''
    session_name: dev
    windows:
    - window_name: main
      layout: tiled
  '';
}
