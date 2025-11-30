# Fish shell configuration
#
# Fish config is managed by chezmoi because:
# - Contains encrypted abbreviations file that needs chezmoi's decryption
# - Will be migrated to sops-nix in Phase 5
#
# This module only provides the fish package via home-manager.
{ config, lib, pkgs, ... }:

{
  # Install fish package
  home.packages = [ pkgs.fish ];

  # NOTE: ~/.config/fish is managed by chezmoi, not Nix
  # The config includes encrypted files (abbreviations) that require
  # chezmoi's decryption. After Phase 5 (sops-nix migration), we can
  # revisit using mkOutOfStoreSymlink or programs.fish.
}
