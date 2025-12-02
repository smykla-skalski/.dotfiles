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
      url = "github:bartsmykla/af";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ self, nixpkgs, nix-darwin, home-manager, sops-nix, af, ... }:
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

              # Third-party taps
              taps = [
                "bufbuild/buf"
                "chipmk/tap"
                "speakeasy-api/tap"
                "aquaproj/aqua"
                "aquasecurity/trivy"
                "cyclonedx/cyclonedx"
                "derailed/popeye"
                "hashicorp/tap"
                "mutagen-io/mutagen"
                "helm/tap"
                "grafana/grafana"
                "pamburus/tap"
                "homebrew/services"
              ];

              # Formulas not available in nixpkgs
              brews = [
                "chipmk/tap/docker-mac-net-connect" # Docker networking
                "cyclonedx/cyclonedx/cyclonedx-cli" # CycloneDX SBOM
                "derailed/popeye/popeye"  # Kubernetes cluster linter
                "mutagen-io/mutagen/mutagen" # File sync
                "pamburus/tap/hl"         # JSON log viewer
                "lnav"                    # Log viewer (HEAD build)
                "kumactl"                 # Kuma service mesh CLI
                "swiftlint"               # Swift linter
                "vale"                    # Prose linter
                "cfn-lint"                # CloudFormation linter
                "commitlint"              # Commit message linter
                "check-jsonschema"        # JSON Schema validator
                "aqua"                    # CLI version manager
                "chart-releaser"          # Helm charts releaser
                "vexctl"                  # VEX metadata tool
                "muffet"                  # Website link checker
                "speakeasy-api/tap/speakeasy" # API client generation
                "toxiproxy"               # TCP proxy for chaos
                "kubeshark"               # Kubernetes network analyzer
                "jump"                    # Directory bookmarking
              ];

              # GUI Applications (casks)
              casks = [
                # Essential
                "1password-cli"
                "alfred"
                "rectangle"

                # Terminals
                "alacritty"
                "iterm2"
                "kitty"

                # Browsers
                "brave-browser"
                "firefox@developer-edition"
                "opera"

                # Development
                "cursor"
                "visual-studio-code"
                "jetbrains-toolbox"
                "insomnia"

                # AI Tools
                "chatgpt"
                "claude"

                # Container & Kubernetes
                "orbstack"
                "rancher"

                # Cloud
                "gcloud-cli"

                # Communication
                "discord"
                "signal"

                # Utilities
                "bartender"
                "caffeine"
                "hiddenbar"
                "raycast"
                "send-to-kindle"

                # Productivity
                "obsidian"
                "omnigraffle"

                # Security & Networking
                "gpg-suite"
                "ngrok"
                "wireshark-app"

                # Gaming/Peripherals
                "steelseries-gg"

                # Infrastructure
                "hashicorp-vagrant"

                # Fonts
                "font-fira-code"
                "font-fira-code-nerd-font"
                "font-fira-mono-nerd-font"
              ];
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
                  sops-nix.homeManagerModules.sops
                  ./modules/home/alacritty.nix
                  ./modules/home/atuin.nix
                  ./modules/home/bash.nix
                  ./modules/home/broot.nix
                  ./modules/home/broot-tips.nix
                  ./modules/home/claude.nix
                  ./modules/home/direnv.nix
                  ./modules/home/exercism.nix
                  ./modules/home/fish.nix
                  ./modules/home/gocheat-broot.nix
                  ./modules/home/grype.nix
                  ./modules/home/k9s.nix
                  ./modules/home/lnav.nix
                  ./modules/home/mise.nix
                  ./modules/home/packages.nix
                  ./modules/home/sops.nix
                  ./modules/home/starship.nix
                  ./modules/home/syft.nix
                  ./modules/home/tmux.nix
                  ./modules/home/tmuxp.nix
                  ./modules/home/vim.nix
                ];

                home.username = username;
                home.homeDirectory = lib.mkForce "/Users/bart.smykla@konghq.com";
                home.stateVersion = "24.05";

                programs.home-manager.enable = true;

                programs.git = {
                  enable = true;
                  settings.user.name = "Bart Smykla";
                  settings.user.email = "bartek@smykla.com";
                };

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
            };
            envUser = builtins.getEnv "USER";
            envHome = builtins.getEnv "HOME";
            userName = if envUser != "" then envUser else username;
            userHome = if envHome != "" then envHome else "/Users/${username}";
          in
          home-manager.lib.homeManagerConfiguration {
            pkgs = hmPkgs;
            modules = [
              {
                home.username = userName;
                home.homeDirectory = userHome;
                home.stateVersion = "24.05";
                # Add af package from flake input
                home.packages = [ af.packages.${system}.default ];
              }
              sops-nix.homeManagerModules.sops
              ./modules/home/alacritty.nix
              ./modules/home/atuin.nix
              ./modules/home/bash.nix
              ./modules/home/broot.nix
              ./modules/home/broot-tips.nix
              ./modules/home/claude.nix
              ./modules/home/direnv.nix
              ./modules/home/exercism.nix
              ./modules/home/fish.nix
              ./modules/home/gocheat-broot.nix
              ./modules/home/grype.nix
              ./modules/home/k9s.nix
              ./modules/home/lnav.nix
              ./modules/home/mise.nix
              ./modules/home/packages.nix
              ./modules/home/sops.nix
              ./modules/home/starship.nix
              ./modules/home/syft.nix
              ./modules/home/tmux.nix
              ./modules/home/tmuxp.nix
              ./modules/home/vim.nix
            ];
          };
      };
    };
}
