# ToolHive Studio - MCP server manager desktop application
#
# ToolHive is a desktop application for discovering, deploying, and managing
# Model Context Protocol (MCP) servers in locked-down containers.
{ config, lib, pkgs, ... }:

let
  toolhive-studio = pkgs.stdenvNoCC.mkDerivation rec {
    pname = "ToolHive";
    version = "0.14.1";

    src = pkgs.fetchurl {
      url = "https://github.com/stacklok/toolhive-studio/releases/download/v${version}/ToolHive-arm64.dmg";
      sha256 = "0wpn1917p1wm1g6ca0faxjdcwbmrdfyxv2612b751hiaskxg187q";
    };

    nativeBuildInputs = [ pkgs.undmg ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p "$out/Applications"
      cp -r ToolHive.app "$out/Applications/"
    '';

    meta = with lib; {
      description = "Desktop application for managing MCP servers";
      homepage = "https://toolhive.dev";
      platforms = platforms.darwin;
      license = licenses.unfree;
    };
  };
in
{
  # Install ToolHive Studio to ~/Applications
  home.packages = [ toolhive-studio ];

  # Create symlink from nix store to ~/Applications
  # This makes the app visible in Spotlight and Launchpad
  home.activation.toolhiveStudio = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p "$HOME/Applications"
    $DRY_RUN_CMD rm -f "$HOME/Applications/ToolHive.app"
    $DRY_RUN_CMD ln -sf "${toolhive-studio}/Applications/ToolHive.app" "$HOME/Applications/ToolHive.app"
  '';
}
