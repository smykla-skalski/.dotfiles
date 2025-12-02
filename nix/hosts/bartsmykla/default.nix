{ pkgs, lib, ... }:

{
  # Set hostname to match flake configuration name
  networking.hostName = "bartsmykla";
  networking.computerName = "bartsmykla";
  networking.localHostName = "bartsmykla";

  # Host-specific nixpkgs platform
  nixpkgs.hostPlatform = "aarch64-darwin";
}
