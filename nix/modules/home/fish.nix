# Fish shell configuration (main orchestrator)
#
# This module imports all fish-related configurations in a modular structure.
# Individual configurations can be found in the fish/ subdirectory.
{ pkgs, ... }:

{
  imports = [
    ./fish/abbreviations.nix
    ./fish/environment.nix
    ./fish/functions
    ./fish/plugins.nix
    ./fish/keybindings.nix
    ./fish/completions.nix
  ];

  programs.fish = {
    enable = true;
    shellAliases = { };
  };

  home.packages = with pkgs; [
    fzf
  ];
}
