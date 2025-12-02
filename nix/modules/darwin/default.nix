{ pkgs, lib, config, ... }:

{
  imports = [
    ./homebrew.nix
    ./system-defaults.nix
    ./security.nix
  ];

  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ git ];

  # Enable fish shell system-wide with nix-darwin paths
  programs.fish = {
    enable = true;
    # Use babelfish to pre-translate bash scripts at build time
    # instead of foreign-env (fenv) translating at runtime (~250ms savings)
    useBabelfish = true;
    babelfishPackage = pkgs.babelfish;
    shellInit = ''
      # Add nix-darwin managed paths
      fish_add_path --prepend --move /run/current-system/sw/bin
      fish_add_path --prepend --move /etc/profiles/per-user/$USER/bin
      fish_add_path --prepend --move $HOME/.nix-profile/bin
    '';
  };

  system.stateVersion = 5;
}
