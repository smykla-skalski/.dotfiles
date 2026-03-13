# Brewfile - Homebrew Package Management
#
# PURPOSE:
#   Declarative package management for all Homebrew installations (formulas, casks, taps)
#
# USAGE:
#   Install all packages:     brew bundle install
#   Check what's missing:     brew bundle check
#   Cleanup unused packages:  brew bundle cleanup
#   Update this file:         brew bundle dump --force --describe
#
# BEST PRACTICES:
#   - Keep taps before formulas (dependency order)
#   - Group related packages together
#   - Use comments to explain non-obvious packages
#   - Pin versions only when needed (prefer latest)
#
# REFERENCE:
#   https://docs.brew.sh/Brew-Bundle
#   https://docs.brew.sh/Manpage#bundle-subcommand

# ==============================================================================
# TAPS - Third-party Homebrew repositories
# ==============================================================================
# Personal tap for custom tools
tap "smykla-skalski/tap", "git@github.com:smykla-skalski/homebrew-tap.git"

# Development tools
tap "bufbuild/buf"           # Protocol Buffers tooling
tap "chipmk/tap"             # Docker networking utilities
tap "speakeasy-api/tap"      # API development tools

# Infrastructure & Security
tap "aquaproj/aqua"          # Declarative CLI version manager
tap "aquasecurity/trivy"     # Container security scanner
tap "cyclonedx/cyclonedx"    # Software Bill of Materials (SBOM)
tap "derailed/popeye"        # Kubernetes cluster linter
tap "hashicorp/tap"          # HashiCorp tools
tap "mutagen-io/mutagen"     # File synchronization

# Kubernetes & Cloud
tap "helm/tap"               # Kubernetes package manager
tap "grafana/grafana"        # Observability platform

# Log analysis
tap "pamburus/tap"           # JSON log viewer

# Official Homebrew taps
tap "homebrew/cask-fonts"    # Fonts as casks
tap "homebrew/cask-versions" # Beta/development versions
tap "homebrew/services"      # Service management (brew services)

# ==============================================================================
# CLI TOOLS - Core utilities and replacements
# ==============================================================================
# Modern Unix tools (better alternatives to standard tools)
brew "bat"          # cat with syntax highlighting
brew "eza"          # ls replacement with icons and git integration
brew "fd"           # find replacement (faster, simpler syntax)
brew "fzf"          # Fuzzy finder for command-line
brew "the_silver_searcher"  # ag - faster grep alternative
brew "ack"          # Search tool optimized for programmers

# Shell & Terminal
brew "fish"         # User-friendly shell (primary shell)
brew "bash"         # Bourne-Again Shell (compatibility)
brew "starship"     # Cross-shell prompt with Git integration
brew "atuin", restart_service: :changed  # Shell history sync (runs as service)
brew "tmux"         # Terminal multiplexer
brew "tmuxp"        # Tmux session manager

# File Management & Navigation
brew "broot"        # Directory tree navigation
brew "jump"         # Directory bookmarking (learning-based)
brew "tree"         # Directory tree display
brew "direnv"       # Per-directory environment variables

# Text Processing & Viewing
brew "jq"           # JSON processor
brew "yq"           # YAML/JSON/XML processor
brew "fx"           # Terminal JSON viewer (interactive)
brew "lnav", args: ["HEAD"]  # Log file viewer (using latest from HEAD)

# ==============================================================================
# DEVELOPMENT TOOLS
# ==============================================================================
# Version Control
brew "git"          # Distributed version control
brew "git-crypt"    # Transparent file encryption in git
brew "gh"           # GitHub CLI

# Build Tools & Compilers
brew "make"         # GNU Make
brew "cmake"        # Cross-platform make
brew "ninja"        # Small build system
brew "autoconf"     # Automatic configure script builder
brew "clang-format" # Code formatter (C/C++/Java/JS/TS)
brew "llvm"         # Next-gen compiler infrastructure

# Container & Kubernetes Tools
brew "docker"       # Container runtime
brew "k3d"          # k3s in Docker (local k8s)
brew "kind"         # Kubernetes IN Docker
brew "minikube"     # Local Kubernetes
brew "kubernetes-cli"  # kubectl
brew "kubectx"      # Switch kubectl contexts easily
brew "k9s"          # Kubernetes TUI
brew "kubeshark"    # Kubernetes network analyzer
brew "helm"         # Kubernetes package manager
brew "kustomize"    # Kubernetes manifest customization
brew "kumactl"      # Kuma service mesh CLI
brew "skaffold"     # Kubernetes development workflow
brew "stern"        # Tail logs from multiple pods

# Container Image Tools
brew "crane"        # Tool for interacting with registries
brew "skopeo"       # Work with remote image registries

# Cloud CLIs
brew "awscli"       # AWS CLI
brew "azure-cli"    # Azure CLI
brew "saml2aws"     # AWS login via SAML IDP
brew "eksctl"       # Amazon EKS CLI

# Infrastructure as Code
brew "terraform"    # HashiCorp Terraform (IaC)
brew "opentofu"     # OpenTofu (Terraform fork)

# Security & Vulnerability Scanning
brew "grype"        # Vulnerability scanner for containers
brew "syft"         # SBOM generator
brew "trivy", link: false  # Container vulnerability scanner
brew "snyk-cli"     # Snyk security scanner
brew "osv-scanner"  # OSV vulnerability database scanner
brew "scorecard"    # OpenSSF security metrics

# Linters & Formatters
brew "actionlint"   # GitHub Actions workflow linter
brew "cfn-lint"     # CloudFormation template validator
brew "commitlint"   # Commit message linter
brew "hadolint"     # Dockerfile linter
brew "swiftlint"    # Swift code linter
brew "vale"         # Prose linter
brew "yamllint"     # YAML linter
brew "shellcheck"   # Shell script linter (installed via mise)

# Testing Tools
brew "check-jsonschema"  # JSON Schema validator (supports Taskfile)
brew "shellspec"         # Shell script testing framework (BDD-style)

# Protocol Buffers
brew "bufbuild/buf/buf"  # Protocol Buffers tooling
brew "buildifier"        # Bazel BUILD file formatter
brew "buildozer"         # Bazel BUILD file editor

# API Development
brew "muffet"       # Website link checker
brew "speakeasy-api/tap/speakeasy"  # API client generation

# Monitoring & Debugging
brew "htop"         # Interactive process viewer
brew "watch"        # Execute program periodically
brew "socat"        # SOcket CAT (netcat on steroids)
brew "toxiproxy"    # TCP proxy for chaos testing

# ==============================================================================
# PACKAGE MANAGERS & VERSION MANAGERS
# ==============================================================================
brew "aqua"         # Declarative CLI version manager
brew "pre-commit"   # Git pre-commit hooks framework

# ==============================================================================
# UTILITIES
# ==============================================================================
# Network Tools
brew "ipcalc"       # IP subnet calculator
brew "sipcalc"      # Advanced IP subnet calculator
brew "iproute2mac"  # IP command for macOS
brew "wget"         # Internet file retriever

# Cryptography & Security
brew "gnupg"        # GNU Privacy Guard
brew "openssl@3"    # Latest OpenSSL

# Media Processing
brew "ffmpeg"       # Audio/video processing
brew "imagemagick"  # Image manipulation

# System Tools
brew "coreutils"    # GNU core utilities
brew "findutils"    # GNU find, xargs, locate
brew "gnu-tar"      # GNU tar
brew "grep"         # GNU grep
brew "flock"        # File locking utility

# Documentation & Help
brew "help2man"     # Generate man pages
brew "tlrc"         # tldr client (command examples)

# Misc Utilities
brew "aspell"       # Spell checker
brew "gum"          # Shell script styling tool
brew "usage"        # Tool for usage-spec CLIs
brew "terminal-notifier"  # macOS notifications from CLI

# Development Libraries
brew "capstone"     # Disassembly framework
brew "graphviz"     # Graph visualization
brew "libpq", link: true  # Postgres C API
brew "libtool"      # Generic library support
brew "pkgconf"      # Package compiler metadata
brew "zlib"         # Data compression library

# ==============================================================================
# CUSTOM TAP FORMULAS
# ==============================================================================
brew "smykla-skalski/tap/af"  # Personal CLI tool
brew "chipmk/tap/docker-mac-net-connect"  # Docker-for-Mac IP access
brew "cyclonedx/cyclonedx/cyclonedx-cli"  # CycloneDX SBOM tool
brew "derailed/popeye/popeye"  # Kubernetes cluster linter
brew "mutagen-io/mutagen/mutagen"  # File sync for remote dev
brew "pamburus/tap/hl"  # JSON/logfmt log viewer

# Editors & IDEs
brew "vim"          # Vi IMproved

# Container Management (deprecated in favor of OrbStack)
brew "overmind"     # Process manager for tmux

# Bazel
brew "bazelisk"     # User-friendly Bazel launcher

# Chart Tools
brew "chart-releaser"  # Helm Charts via GitHub

# VEX (Vulnerability Exchange)
brew "vexctl"       # VEX metadata tool

# Misc
brew "exercism"     # exercism.io CLI

# ==============================================================================
# GUI APPLICATIONS (CASKS)
# ==============================================================================
# Essential Apps
cask "1password-cli"     # 1Password command-line interface
cask "alfred"            # Application launcher and productivity
cask "rectangle"         # Window management via keyboard

# Terminals
cask "alacritty"         # GPU-accelerated terminal (primary)
cask "iterm2"            # Alternative terminal
cask "kitty"             # GPU-based terminal

# Browsers
cask "brave-browser"     # Privacy-focused browser
cask "firefox@developer-edition"  # Firefox Developer Edition
cask "opera"             # Opera browser

# Development Tools
cask "cursor"            # AI-powered code editor
cask "visual-studio-code"  # VS Code
cask "jetbrains-toolbox"  # JetBrains IDE manager
cask "insomnia"          # HTTP/GraphQL client

# AI Tools
cask "chatgpt"           # OpenAI ChatGPT desktop app
cask "claude"            # Anthropic Claude AI desktop app

# Container & Kubernetes
cask "orbstack"          # Docker Desktop replacement (preferred)
cask "rancher"           # Kubernetes management

# Cloud Tools
cask "gcloud-cli"        # Google Cloud SDK

# Communication
cask "discord"           # Voice and text chat
cask "signal"            # Secure messaging

# Utilities
cask "bartender"         # Menu bar organizer
cask "caffeine"          # Prevent system sleep
cask "hiddenbar"         # Hide menu bar items
cask "raycast"           # Command launcher
cask "send-to-kindle"    # Send documents to Kindle

# Productivity
cask "obsidian"          # Knowledge base (Markdown)
cask "omnigraffle"       # Diagramming tool

# Security & Networking
cask "gpg-suite"         # GPG tools for macOS
cask "ngrok"             # Secure tunnels to localhost
cask "wireshark-app"     # Network protocol analyzer

# Gaming/Peripherals
cask "steelseries-gg"    # SteelSeries peripheral settings

# Development (Infrastructure)
cask "hashicorp-vagrant"  # Development environment manager

# Fonts
cask "font-fira-code"           # Fira Code font
cask "font-fira-code-nerd-font" # Fira Code with icons
cask "font-fira-mono-nerd-font" # Fira Mono with icons

# ==============================================================================
# VS CODE EXTENSIONS
# ==============================================================================
# Note: These are auto-generated. Manage via VS Code or `code --install-extension`
vscode "anthropic.claude-code"
vscode "bierner.markdown-preview-github-styles"
vscode "eamodio.gitlens"
vscode "emmanuelbeziat.vscode-great-icons"
vscode "file-icons.file-icons"
vscode "github.copilot"
vscode "github.copilot-chat"
vscode "github.vscode-github-actions"
vscode "github.vscode-pull-request-github"
vscode "golang.go"
vscode "grafana.grafana-alloy"
vscode "k--kato.intellij-idea-keybindings"
vscode "lnav.lnav"
vscode "mechatroner.rainbow-csv"
vscode "monokai.theme-monokai-pro-vscode"
vscode "ms-azuretools.vscode-containers"
vscode "ms-azuretools.vscode-docker"
vscode "ms-kubernetes-tools.vscode-kubernetes-tools"
vscode "ms-python.debugpy"
vscode "ms-python.python"
vscode "ms-python.vscode-pylance"
vscode "ms-sarifvscode.sarif-viewer"
vscode "ms-vscode-remote.remote-containers"
vscode "openai.chatgpt"
vscode "redhat.vscode-yaml"
vscode "repreng.csv"
vscode "yzhang.markdown-all-in-one"

# ==============================================================================
# GO PACKAGES
# ==============================================================================
# Note: Prefer managing Go tools via mise instead of `go install`
# These are tracked for reference but may be redundant
go "cmd/go"
go "cmd/gofmt"
go "github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema"
go "github.com/daixiang0/gci"
go "github.com/google/osv-scanner/cmd/osv-scanner"
go "github.com/onsi/ginkgo/v2/ginkgo"
go "golang.org/x/tools/gopls"
go "honnef.co/go/tools/cmd/staticcheck"
