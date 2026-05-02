{ pkgs, lib, config, ... }:

let
  userHome = "/Users/${config.system.primaryUser}";
in

{
  imports = [
    ./homebrew.nix
    ./system-defaults.nix
    ./security.nix
  ];

  # Disable nix-darwin's Nix management (using Determinate Nix)
  nix.enable = false;
  # Required by sops-nix even when nix.enable = false
  # See: https://github.com/Mic92/sops-nix/issues/531
  nix.package = pkgs.nix;

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [ git ];

  launchd.user.envVariables.PATH = [
    "${userHome}/.local/bin"
    "${userHome}/.nix-profile/bin"
    "/etc/profiles/per-user/${config.system.primaryUser}/bin"
    "/run/current-system/sw/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/usr/local/bin"
    "/usr/local/sbin"
    "/usr/bin"
    "/bin"
    "/usr/sbin"
    "/sbin"
  ];

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

      set -l home_local_bin "$HOME/.local/bin"
      if test -d "$home_local_bin"
        set -gx PATH $home_local_bin (string match -v -- "$home_local_bin" $PATH)
      else
        set -gx PATH (string match -v -- "$home_local_bin" $PATH)
      end
    '';
  };

  system.stateVersion = 5;
}
