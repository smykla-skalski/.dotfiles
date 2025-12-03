{ config, pkgs, lib, ... }:

let
  # Absolute path to dotfiles - required for mkOutOfStoreSymlink with flakes
  dotfilesPath = "${config.home.homeDirectory}/Projects/github.com/smykla-labs/.dotfiles";
in
{
  # GoLand color scheme configuration
  # Manages the "Monokai Bart" color scheme declaratively
  #
  # Uses mkOutOfStoreSymlink to create symlinks directly to dotfiles repo
  # instead of nix store. JetBrains IDEs have issues with nix store symlinks.

  home.file = {
    # Color scheme file (macOS path)
    "Library/Application Support/JetBrains/GoLand2025.2/colors/Monokai Bart.icls" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/goland/colors/Monokai-Bart.icls";
    };

    # Settings sync location
    "Library/Application Support/JetBrains/GoLand2025.2/settingsSync/colors/Monokai Bart.icls" = {
      source = config.lib.file.mkOutOfStoreSymlink "${dotfilesPath}/configs/goland/colors/Monokai-Bart.icls";
    };
  };

  # Note: JetBrains IDEs manage settings statefully, so this configuration
  # provides the color scheme but allows the IDE to modify other settings.
  # To update the color scheme, modify the source file in configs/goland/colors/
  # and rebuild the Nix configuration.
  #
  # The colors.scheme.xml is NOT managed here because:
  # 1. GoLand needs to manage other settings in this file
  # 2. The user can select the scheme via IDE preferences
}
