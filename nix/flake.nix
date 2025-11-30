{
  description = "Nix configuration for smykla-labs dotfiles";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, ... }:
    let
      system = "aarch64-darwin";
      hostname = "bartsmykla";
      # Username with special characters needs careful handling
      username = "bart.smykla@konghq.com";
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Darwin system configuration
          ({ pkgs, lib, ... }: {
            # Required for user-specific options (homebrew, system.defaults, etc.)
            system.primaryUser = username;

            # Disable nix-darwin's Nix management (using Determinate Nix)
            nix.enable = false;

            nixpkgs.config.allowUnfree = true;
            nixpkgs.hostPlatform = system;

            environment.systemPackages = with pkgs; [ git ];

            # Enable fish shell system-wide with nix-darwin paths
            programs.fish = {
              enable = true;
              shellInit = ''
                # Add nix-darwin managed paths
                fish_add_path --prepend --move /run/current-system/sw/bin
                fish_add_path --prepend --move /etc/profiles/per-user/$USER/bin
                fish_add_path --prepend --move $HOME/.nix-profile/bin
              '';
            };

            # Touch ID for sudo (works in tmux with pam-reattach)
            security.pam.services.sudo_local.touchIdAuth = true;
            security.pam.services.sudo_local.reattach = true;

            system.defaults = {
              dock = {
                autohide = true;
                mru-spaces = false;
                show-recents = false;
              };
              finder = {
                AppleShowAllExtensions = true;
                FXPreferredViewStyle = "clmv";
                ShowPathbar = true;
                ShowStatusBar = true;
              };
              NSGlobalDomain = {
                AppleShowAllExtensions = true;
                InitialKeyRepeat = 15;
                KeyRepeat = 2;
              };
            };

            homebrew = {
              enable = true;
              onActivation = {
                autoUpdate = false;
                # "none" = don't remove unlisted packages (safe)
                # "uninstall" = remove unlisted packages
                # "zap" = remove + delete all data (DANGEROUS)
                cleanup = "none";
              };
              casks = [ ];
            };

            # Set hostname to match flake configuration name
            networking.hostName = hostname;
            networking.computerName = hostname;
            networking.localHostName = hostname;

            system.stateVersion = 5;
          })

          # Home-manager module
          home-manager.darwinModules.home-manager
          ({ pkgs, lib, ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.${username} = { pkgs, lib, config, ... }: {
                imports = [
                  ./modules/home/alacritty.nix
                  ./modules/home/fish.nix
                  ./modules/home/starship.nix
                  ./modules/home/tmux.nix
                  ./modules/home/vim.nix
                ];

                home.username = username;
                home.homeDirectory = lib.mkForce "/Users/bart.smykla@konghq.com";
                home.stateVersion = "24.05";

                home.packages = with pkgs; [
                  bat eza fd fzf ripgrep jq
                ];

                programs.home-manager.enable = true;

                programs.git = {
                  enable = true;
                  settings.user.name = "Bart Smykla";
                  settings.user.email = "bartek@smykla.com";
                };
              };
            };
          })
        ];
      };

      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;
    };
}
