{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # ============================================================================
    # Modern Unix Tools (better alternatives to standard tools)
    # ============================================================================
    bat           # cat with syntax highlighting
    eza           # ls replacement with icons and git integration
    fd            # find replacement (faster, simpler syntax)
    fzf           # Fuzzy finder for command-line
    silver-searcher # ag - faster grep alternative
    ack           # Search tool optimized for programmers
    ripgrep       # rg - fastest grep alternative

    # ============================================================================
    # Shell & Terminal
    # ============================================================================
    home-manager  # home-manager CLI in PATH
    # fish - managed via programs.fish
    # bash - system default
    # starship - managed via programs.starship
    # tmux - managed via programs.tmux
    tmuxp         # Tmux session manager
    asciinema     # Terminal session recorder

    # ============================================================================
    # File Management & Navigation
    # ============================================================================
    broot         # Directory tree navigation
    tree          # Directory tree display
    fswatch       # Cross-platform file change monitor
    # direnv - managed via programs.direnv in direnv.nix
    # jump - not in nixpkgs, use zoxide instead
    zoxide        # smarter cd command (jump alternative)

    # ============================================================================
    # Text Processing & Viewing
    # ============================================================================
    jq            # JSON processor
    yq-go         # YAML/JSON/XML processor (mikefarah's yq)
    fx            # Terminal JSON viewer (interactive)
    # lnav - not easily available, keep in Homebrew for HEAD build

    # ============================================================================
    # Version Control
    # ============================================================================
    git           # Distributed version control
    git-crypt     # Transparent file encryption in git
    gh            # GitHub CLI

    # ============================================================================
    # Build Tools & Compilers
    # ============================================================================
    gnumake       # GNU Make
    cmake         # Cross-platform make
    ninja         # Small build system
    autoconf      # Automatic configure script builder
    clang-tools   # clang-format, clang-tidy, etc.
    # llvm - large package, only add if needed

    # ============================================================================
    # Container & Kubernetes Tools
    # ============================================================================
    docker-client # Docker CLI (OrbStack provides daemon)
    k3d           # k3s in Docker (local k8s)
    kind          # Kubernetes IN Docker
    minikube      # Local Kubernetes
    kubectl       # Kubernetes CLI
    kubectx       # Switch kubectl contexts easily
    k9s           # Kubernetes TUI
    # kubeshark - not in nixpkgs, keep in Homebrew
    kubernetes-helm # Helm - Kubernetes package manager
    kustomize     # Kubernetes manifest customization
    # kumactl - not in nixpkgs, install via mise or direct download
    skaffold      # Kubernetes development workflow
    stern         # Tail logs from multiple pods

    # ============================================================================
    # Container Image Tools
    # ============================================================================
    crane         # Tool for interacting with registries (from go-containerregistry)
    skopeo        # Work with remote image registries

    # ============================================================================
    # Cloud CLIs
    # ============================================================================
    awscli2       # AWS CLI v2
    azure-cli     # Azure CLI
    saml2aws      # AWS login via SAML IDP
    eksctl        # Amazon EKS CLI
    # gcloud - managed as cask via Homebrew

    # ============================================================================
    # Infrastructure as Code
    # ============================================================================
    terraform     # HashiCorp Terraform (IaC)
    opentofu      # OpenTofu (Terraform fork)

    # ============================================================================
    # Security & Vulnerability Scanning
    # ============================================================================
    grype         # Vulnerability scanner for containers
    syft          # SBOM generator
    trivy         # Container vulnerability scanner
    snyk          # Snyk security scanner
    osv-scanner   # OSV vulnerability database scanner
    scorecard     # OpenSSF security metrics

    # ============================================================================
    # Linters & Formatters
    # ============================================================================
    actionlint    # GitHub Actions workflow linter
    # cfn-lint - Python package, consider pipx
    # commitlint - npm package, consider via nodePackages
    hadolint      # Dockerfile linter
    # swiftlint - not in nixpkgs for darwin, keep in Homebrew
    # vale - prose linter, not in nixpkgs
    yamllint      # YAML linter
    shellcheck    # Shell script linter
    statix        # Nix linter (finds anti-patterns)
    deadnix       # Nix dead code finder
    alejandra     # Nix formatter

    # ============================================================================
    # Testing Tools
    # ============================================================================
    # check-jsonschema - Python package
    shellspec     # Shell script testing framework (BDD-style)

    # ============================================================================
    # Protocol Buffers
    # ============================================================================
    buf           # Protocol Buffers tooling
    buildifier    # Bazel BUILD file formatter
    buildozer     # Bazel BUILD file editor

    # ============================================================================
    # Monitoring & Debugging
    # ============================================================================
    htop          # Interactive process viewer
    watch         # Execute program periodically (from procps)
    socat         # SOcket CAT (netcat on steroids)
    # toxiproxy - not in nixpkgs

    # ============================================================================
    # Package Managers & Version Managers
    # ============================================================================
    # aqua - not in nixpkgs, keep using mise
    pre-commit    # Git pre-commit hooks framework
    uv            # Extremely fast Python package installer and resolver

    # ============================================================================
    # Network Tools
    # ============================================================================
    ipcalc        # IP subnet calculator
    sipcalc       # Advanced IP subnet calculator
    iproute2mac   # IP command for macOS
    wget          # Internet file retriever

    # ============================================================================
    # Cryptography & Security
    # ============================================================================
    gnupg         # GNU Privacy Guard
    openssl       # OpenSSL

    # ============================================================================
    # Media Processing
    # ============================================================================
    ffmpeg        # Audio/video processing
    imagemagick   # Image manipulation

    # ============================================================================
    # System Tools (GNU coreutils)
    # ============================================================================
    coreutils     # GNU core utilities
    findutils     # GNU find, xargs, locate
    gnutar        # GNU tar
    gnugrep       # GNU grep

    # ============================================================================
    # Documentation & Help
    # ============================================================================
    help2man      # Generate man pages
    tlrc          # tldr client (command examples)

    # ============================================================================
    # Misc Utilities
    # ============================================================================
    aspell        # Spell checker
    gum           # Shell script styling tool
    # usage - not in nixpkgs
    terminal-notifier # macOS notifications from CLI
    graphviz      # Graph visualization
    # vim - managed via programs.vim

    # ============================================================================
    # Development Libraries (if needed as runtime deps)
    # ============================================================================
    # capstone - disassembly framework
    # libpq - Postgres C API
    # libtool - generic library support
    # pkg-config - replaced by pkgconf in nixpkgs
    # zlib - compression library

    # ============================================================================
    # Custom/Third-party tools (not in nixpkgs, keep in Homebrew)
    # ============================================================================
    # bartsmykla/af/af - personal CLI tool
    # docker-mac-net-connect - Docker networking
    # cyclonedx-cli - SBOM tool
    # popeye - Kubernetes cluster linter
    # mutagen - file sync
    # hl - JSON log viewer

    # ============================================================================
    # Bazel
    # ============================================================================
    bazelisk      # User-friendly Bazel launcher

    # ============================================================================
    # Misc Development
    # ============================================================================
    # chart-releaser - not in nixpkgs
    # vexctl - not in nixpkgs
    exercism      # exercism.io CLI
    overmind      # Process manager for tmux
  ];
}
