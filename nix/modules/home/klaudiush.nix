# klaudiush configuration
#
# Validation dispatcher for Claude Code hooks.
# Seeds a mutable XDG config from the tracked template, then leaves it as a
# normal user-owned file so `klaudiush init --global` can update it.
{ config, lib, ... }:

let
  configTemplate = ../../../configs/klaudiush/config.toml;
in
{
  programs.klaudiush = {
    enable = true;
    configFile = lib.mkForce null;
    createDynamicDirs = true;
  };

  home.activation.klaudiushMutableConfig = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    config_dir="$HOME/.config/klaudiush"
    config_path="$config_dir/config.toml"

    $DRY_RUN_CMD mkdir -p "$config_dir"

    # Replace store-backed or out-of-store symlinks with a real file once, but
    # preserve later user edits on subsequent Home Manager switches.
    if [ ! -e "$config_path" ] || [ -L "$config_path" ]; then
      $DRY_RUN_CMD rm -f "$config_path"
      $DRY_RUN_CMD cp "${configTemplate}" "$config_path"
      $DRY_RUN_CMD chmod 600 "$config_path"
    fi
  '';
}
