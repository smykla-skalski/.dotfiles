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

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    af = {
      url = "github:smykla-labs/af";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    klaudiush = {
      url = "github:smykla-labs/klaudiush?dir=nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, sops-nix, af, klaudiush, ... }:
    let
      system = "aarch64-darwin";
      hostname = "bartsmykla";
      # Username with special characters needs careful handling
      username = "bart.smykla@konghq.com";

      # Shared Home Manager module imports (DRY principle)
      homeModules = [
        sops-nix.homeManagerModules.sops
        klaudiush.homeManagerModules.default
        ./modules/home/bash.nix
        ./modules/home/broot.nix
        ./modules/home/broot-tips.nix
        ./modules/home/claude.nix
        ./modules/home/command-suggestions.nix
        ./modules/home/direnv.nix
        ./modules/home/exercism.nix
        ./modules/home/fish.nix
        ./modules/home/ghostty.nix
        ./modules/home/goland.nix
        ./modules/home/grype.nix
        ./modules/home/hammerspoon.nix
        ./modules/home/k9s.nix
        ./modules/home/klaudiush.nix
        ./modules/home/lnav.nix
        ./modules/home/mise.nix
        ./modules/home/navi.nix
        ./modules/home/packages.nix
        ./modules/home/shell-aliases.nix
        ./modules/home/shell-functions.nix
        ./modules/home/sops.nix
        ./modules/home/starship.nix
        ./modules/home/syft.nix
        ./modules/home/tmux.nix
        ./modules/home/tmuxp.nix
        ./modules/home/vim.nix
        ./modules/home/zsh.nix
      ];
    in
    {
      darwinConfigurations.${hostname} = nix-darwin.lib.darwinSystem {
        inherit system;
        modules = [
          # Host-specific configuration
          ./hosts/bartsmykla

          # Darwin system configuration
          ./modules/darwin

          # Set primary user (required for homebrew, system.defaults, etc.)
          { system.primaryUser = username; }

          # Overlay to add klaudiush to pkgs
          ({ pkgs, ... }: {
            nixpkgs.overlays = [
              (final: prev: {
                klaudiush = klaudiush.packages.${system}.default;
              })
            ];
          })

          # Home-manager module
          home-manager.darwinModules.home-manager
          ({ pkgs, lib, ... }: {
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;
              backupFileExtension = "hm-backup";
              users.${username} = { pkgs, lib, config, ... }: {
                imports = homeModules;

                home.username = username;
                home.homeDirectory = lib.mkForce "/Users/bart.smykla@konghq.com";
                home.stateVersion = "24.05";

                programs.home-manager.enable = true;

                programs.git = {
                  enable = true;
                  settings.user.name = "Bart Smykla";
                  settings.user.email = "bartek@smykla.com";
                };

                # Suppress "Last login" message
                home.file.".hushlogin".text = "";

                # Add af package from flake input
                home.packages = [ af.packages.${system}.default ];
              };
            };
          })
        ];
      };

      darwinPackages = self.darwinConfigurations.${hostname}.pkgs;

      # Standalone Home Manager entry so the CLI can be run without sudo.
      homeConfigurations = {
        # Short alias to avoid quoting the @ in commands: home-manager switch --flake ./nix#home-bart
        home-bart =
          let
            hmPkgs = import nixpkgs {
              system = "aarch64-darwin";
              config.allowUnfree = true;
              overlays = [
                (final: prev: {
                  klaudiush = klaudiush.packages.${system}.default;
                })
              ];
            };
            envUser = builtins.getEnv "USER";
            envHome = builtins.getEnv "HOME";
            userName = if envUser != "" then envUser else username;
            userHome = if envHome != "" then envHome else "/Users/${username}";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = hmPkgs;
            modules = homeModules ++ [
              {
                home.username = userName;
                home.homeDirectory = userHome;
                home.stateVersion = "24.05";
                # Suppress "Last login" message
                home.file.".hushlogin".text = "";
                # Add af package from flake input
                home.packages = [ af.packages.${system}.default ];
              }
            ];
          };
      };
    };
}
