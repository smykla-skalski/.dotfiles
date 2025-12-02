{ pkgs, lib, ... }:

{
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
      "bufbuild/buf"                          # Protocol buffers
      "chipmk/tap"                            # Docker networking
      "speakeasy-api/tap"                     # API tooling
      "aquaproj/aqua"                         # Version manager
      "aquasecurity/trivy"                    # Security scanner
      "cyclonedx/cyclonedx"                   # SBOM tools
      "derailed/popeye"                       # Kubernetes linter
      "hashicorp/tap"                         # HashiCorp tools
      "mutagen-io/mutagen"                    # File sync
      "helm/tap"                              # Helm charts
      "grafana/grafana"                       # Monitoring
      "pamburus/tap"                          # Log viewer
      "homebrew/services"                     # Service management
    ];

    # Formulas not available in nixpkgs
    brews = [
      "chipmk/tap/docker-mac-net-connect"     # Docker networking
      "cyclonedx/cyclonedx/cyclonedx-cli"     # CycloneDX SBOM
      "derailed/popeye/popeye"                # Kubernetes cluster linter
      "mutagen-io/mutagen/mutagen"            # File sync
      "pamburus/tap/hl"                       # JSON log viewer
      "lnav"                                  # Log viewer
      "kumactl"                               # Kuma service mesh CLI
      "swiftlint"                             # Swift linter
      "vale"                                  # Prose linter
      "cfn-lint"                              # CloudFormation linter
      "commitlint"                            # Commit message linter
      "check-jsonschema"                      # JSON Schema validator
      "aqua"                                  # CLI version manager
      "chart-releaser"                        # Helm charts releaser
      "vexctl"                                # VEX metadata tool
      "muffet"                                # Website link checker
      "speakeasy-api/tap/speakeasy"           # API client generation
      "toxiproxy"                             # TCP proxy for chaos
      "kubeshark"                             # Kubernetes network analyzer
      "jump"                                  # Directory bookmarking
    ];

    # GUI Applications (casks)
    casks = [
      "1password-cli"                         # Password manager CLI
      "alfred"                                # Productivity launcher
      "hammerspoon"                           # macOS automation
      "rectangle"                             # Window management
      "alacritty"                             # GPU terminal emulator
      "iterm2"                                # Terminal emulator
      "kitty"                                 # GPU terminal emulator
      "brave-browser"                         # Privacy browser
      "firefox@developer-edition"             # Firefox dev edition
      "opera"                                 # Web browser
      "cursor"                                # AI code editor
      "visual-studio-code"                    # Code editor
      "jetbrains-toolbox"                     # JetBrains IDE manager
      "insomnia"                              # API client
      "chatgpt"                               # OpenAI ChatGPT
      "claude"                                # Anthropic Claude
      "orbstack"                              # Docker/Linux VMs
      "rancher"                               # Kubernetes management
      "gcloud-cli"                            # Google Cloud CLI
      "discord"                               # Voice/text chat
      "signal"                                # Secure messaging
      "bartender"                             # Menu bar organizer
      "caffeine"                              # Prevent sleep
      "hiddenbar"                             # Menu bar management
      "raycast"                               # Productivity launcher
      "send-to-kindle"                        # Kindle file sender
      "obsidian"                              # Knowledge base
      "omnigraffle"                           # Diagramming tool
      "gpg-suite"                             # GPG encryption
      "ngrok"                                 # Tunnel service
      "wireshark-app"                         # Network analyzer
      "steelseries-gg"                        # Gaming peripherals
      "hashicorp-vagrant"                     # VM management
      "font-fira-code"                        # Programming font
      "font-fira-code-nerd-font"              # Nerd font variant
      "font-fira-mono-nerd-font"              # Monospace nerd font
    ];
  };
}
