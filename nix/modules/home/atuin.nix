# Atuin shell history configuration
#
# DISABLED: Migrated to fzf + native Fish history for simplicity
# fzf history search provides multi-select with Tab/Shift+Tab
#
# To re-enable Atuin, set enable = true below.
{ config, lib, pkgs, ... }:

{
  programs.atuin = {
    enable = false;

    # Enable fish shell integration
    enableFishIntegration = true;

    settings = {
      # Execute command on enter (instead of editing)
      enter_accept = true;

      # Enable sync v2 for new installs
      sync.records = true;

      # Other settings left at defaults
    };
  };
}
