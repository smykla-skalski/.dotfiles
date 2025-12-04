#!/usr/bin/env bash
#
# Bootstrap script for bartsmykla's dotfiles
# Usage: curl -fsSL https://smyk.la | bash
#        curl -fsSL https://smyk.la | bash -s -- --yes
#        curl -fsSL https://smyk.la | bash -s -- --dir ~/my-dotfiles

# shellcheck disable=SC2310  # Functions in conditions with set -e is expected behavior

set -euo pipefail

# Configuration
readonly REPO_ORG="bartsmykla"
readonly REPO_NAME=".dotfiles"
readonly REPO_URL="https://github.com/${REPO_ORG}/${REPO_NAME}.git"
readonly AGE_KEY_PATH="${HOME}/.config/age/key.txt"
readonly AGE_KEY_OP_ID="dyhxf4wgavxqwt23wbsl5my2m"

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Flags and configurable options
YES_FLAG=false
BOOTSTRAP_DIR="${BOOTSTRAP_DIR:-${HOME}/Projects/github.com/${REPO_ORG}/${REPO_NAME}}"
TARGET_DIR="${BOOTSTRAP_DIR}"

#
# Helper functions
#

log_info() {
    echo -e "${BLUE}==>${NC} $*"
}

log_success() {
    echo -e "${GREEN}==>${NC} $*"
}

log_warn() {
    echo -e "${YELLOW}==>${NC} $*"
}

log_error() {
    echo -e "${RED}==>${NC} $*" >&2
}

die() {
    log_error "$@"
    exit 1
}

trim() {
    local var="$1"
    # Remove leading whitespace
    var="${var#"${var%%[![:space:]]*}"}"
    # Remove trailing whitespace
    var="${var%"${var##*[![:space:]]}"}"
    echo "${var}"
}

prompt_yes_no() {
    local prompt="$1"
    local default="${2:-n}"

    if [[ "${YES_FLAG}" == "true" ]]; then
        return 0
    fi

    local yn
    if [[ "${default}" == "y" ]]; then
        read -rp "${prompt} [Y/n] " yn
        yn="${yn:-y}"
    else
        read -rp "${prompt} [y/N] " yn
        yn="${yn:-n}"
    fi

    case "${yn}" in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) log_warn "Invalid response, assuming no"; return 1 ;;
    esac
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

#
# Prerequisites checks
#

check_macos() {
    log_info "Checking macOS..."
    if [[ "$(uname)" != "Darwin" ]]; then
        die "This script only supports macOS"
    fi
    log_success "Running on macOS $(sw_vers -productVersion)"
}

check_internet() {
    log_info "Checking internet connectivity..."
    if ! ping -c 1 -W 2 github.com >/dev/null 2>&1; then
        die "No internet connection detected"
    fi
    log_success "Internet connection verified"
}

check_git() {
    log_info "Checking git..."
    if ! command_exists git; then
        die "git not found. Please install Xcode Command Line Tools: xcode-select --install"
    fi
    log_success "git found: $(git --version)"
}

#
# Homebrew installation
#

install_homebrew() {
    log_info "Checking Homebrew..."
    if command_exists brew; then
        log_success "Homebrew already installed: $(brew --version | head -n1)"
        return 0
    fi

    log_warn "Homebrew not found"
    if ! prompt_yes_no "Install Homebrew?" "y"; then
        die "Homebrew is required for installation"
    fi

    log_info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    if [[ -x /opt/homebrew/bin/brew ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [[ -x /usr/local/bin/brew ]]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed successfully"
}

#
# Repository cloning
#

clone_repository() {
    log_info "Checking repository..."

    if [[ -d "${TARGET_DIR}" ]]; then
        log_warn "Repository already exists at ${TARGET_DIR}"
        if prompt_yes_no "Update existing repository?" "y"; then
            log_info "Updating repository..."
            cd "${TARGET_DIR}"
            git fetch origin
            git reset --hard origin/main
            log_success "Repository updated"
        else
            log_info "Using existing repository"
        fi
        return 0
    fi

    log_info "Cloning repository to ${TARGET_DIR}..."
    mkdir -p "$(dirname "${TARGET_DIR}")"
    git clone "${REPO_URL}" "${TARGET_DIR}"
    log_success "Repository cloned successfully"
}

#
# Age encryption key setup
#

setup_age_key() {
    log_info "Checking age encryption key..."

    if [[ -f "${AGE_KEY_PATH}" ]]; then
        log_success "Age key already exists"
        return 0
    fi

    mkdir -p "$(dirname "${AGE_KEY_PATH}")"

    # Try 1Password CLI first
    if command_exists op; then
        log_info "1Password CLI detected, attempting to retrieve age key..."

        if op document get "${AGE_KEY_OP_ID}" > "${AGE_KEY_PATH}" 2>/dev/null; then
            chmod 600 "${AGE_KEY_PATH}"
            log_success "Age key retrieved from 1Password"
            return 0
        else
            log_warn "Failed to retrieve age key from 1Password (you may need to run 'op signin' first)"
        fi
    fi

    # Fallback to manual paste
    if [[ "${YES_FLAG}" == "true" ]]; then
        die "Age key is required. Install and configure 1Password CLI, or run without --yes flag to enter key manually"
    fi

    log_warn "Age encryption key required"
    echo "Please paste your age key (it should start with 'AGE-SECRET-KEY-'),"
    echo "then press Ctrl-D (without pressing Enter first):"

    local key_content
    key_content=$(trim "$(cat)")

    if [[ ! "${key_content}" =~ ^AGE-SECRET-KEY- ]]; then
        die "Invalid age key format"
    fi

    echo "${key_content}" > "${AGE_KEY_PATH}"
    chmod 600 "${AGE_KEY_PATH}"
    log_success "Age key saved successfully"
}

#
# Git filter configuration
#

configure_git_filters() {
    log_info "Configuring git age filters..."

    cd "${TARGET_DIR}"

    local clean_script="${TARGET_DIR}/.git/age-clean.sh"
    local smudge_script="${TARGET_DIR}/.git/age-smudge.sh"
    local cache_script="${TARGET_DIR}/.git/age-cache-populate.sh"

    # Copy age filter scripts from repository
    if [[ ! -f "${TARGET_DIR}/scripts/git-filters/age-clean.sh" ]] || \
       [[ ! -f "${TARGET_DIR}/scripts/git-filters/age-smudge.sh" ]]; then
        die "Age filter scripts not found in repository"
    fi

    cp "${TARGET_DIR}/scripts/git-filters/age-clean.sh" "${clean_script}"
    cp "${TARGET_DIR}/scripts/git-filters/age-smudge.sh" "${smudge_script}"
    cp "${TARGET_DIR}/scripts/git-filters/age-cache-populate.sh" "${cache_script}"

    chmod +x "${clean_script}" "${smudge_script}" "${cache_script}"

    git config filter.age.clean "${clean_script}"
    git config filter.age.smudge "${smudge_script}"
    git config diff.age.textconv "bash ${smudge_script}"

    # Populate age encryption cache
    bash "${cache_script}"

    log_success "Git age filters configured"
}

#
# Install dependencies
#

install_dependencies() {
    log_info "Installing dependencies via Taskfile..."

    cd "${TARGET_DIR}"

    # Ensure task is available (via Homebrew or mise)
    if ! command_exists task; then
        if command_exists brew; then
            log_info "Installing Task via Homebrew..."
            brew install go-task
        else
            die "Task not found and Homebrew not available"
        fi
    fi

    log_info "Running 'task install' (this may take a while)..."
    task install

    log_success "Dependencies installed successfully"
}

#
# Plugin installation
#

install_vim_plugins() {
    log_info "Installing Vim plugins..."

    if [[ ! -f "${HOME}/.vimrc" ]]; then
        log_warn "Vim config not found, skipping plugin installation"
        return 0
    fi

    log_info "Running Vundle plugin installation..."
    vim +PluginInstall +qall || log_warn "Vim plugin installation had warnings"

    log_success "Vim plugins installed"
}

install_tmux_plugins() {
    log_info "Checking Tmux Plugin Manager..."

    local tpm_dir="${HOME}/.tmux/plugins/tpm"

    if [[ ! -d "${tpm_dir}" ]]; then
        log_info "Installing Tmux Plugin Manager..."
        git clone https://github.com/tmux-plugins/tpm "${tpm_dir}"
    fi

    log_success "Tmux Plugin Manager ready"
    log_info "Note: Start tmux and press 'prefix + I' to install plugins"
}

#
# Git hooks
#

install_git_hooks() {
    log_info "Installing git hooks..."

    cd "${TARGET_DIR}"
    task hooks:install

    log_success "Git hooks installed"
}

#
# Verification
#

run_verification() {
    log_info "Running verification tests..."

    cd "${TARGET_DIR}"

    log_info "Running linters..."
    if ! task lint; then
        log_warn "Linting failed, but continuing..."
    fi

    log_info "Running tests..."
    if ! task test; then
        log_warn "Tests failed, but continuing..."
    fi

    log_success "Verification complete"
}

#
# Post-installation message
#

print_success_message() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Dotfiles installation complete! 🎉"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Next steps:"
    echo ""
    echo "  1. Deploy dotfiles via home-manager:"
    echo "     home-manager switch --flake ${TARGET_DIR}/nix#home-bart"
    echo ""
    echo "  2. Restart your terminal or run:"
    echo "     exec \$(which fish)"
    echo ""
    echo "  3. Install Tmux plugins:"
    echo "     - Start tmux: tmux"
    echo "     - Press: Ctrl-b + I"
    echo ""
    echo "  4. Verify configuration:"
    echo "     cd ${TARGET_DIR}"
    echo "     task test"
    echo ""
    echo "Repository location: ${TARGET_DIR}"
    echo ""
    echo "For more information:"
    echo "  - README: ${TARGET_DIR}/README.md"
    echo "  - Contributing: ${TARGET_DIR}/CONTRIBUTING.md"
    echo "  - Troubleshooting: ${TARGET_DIR}/TROUBLESHOOTING.md"
    echo ""
}

#
# Main installation flow
#

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                YES_FLAG=true
                shift
                ;;
            --dir)
                if [[ -z "${2:-}" || "${2:-}" == -* ]]; then
                    die "--dir requires a value"
                fi
                BOOTSTRAP_DIR="$2"
                TARGET_DIR="${BOOTSTRAP_DIR}"
                shift 2
                ;;
            --help|-h)
                echo "Bootstrap script for bartsmykla's dotfiles"
                echo ""
                echo "Usage:"
                echo "  curl -fsSL https://smyk.la | bash"
                echo "  curl -fsSL https://smyk.la | bash -s -- [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --yes, -y          Skip confirmation prompts"
                echo "  --dir DIRECTORY    Installation directory (default: ~/Projects/github.com/smykla-labs/.dotfiles)"
                echo "  --help, -h         Show this help"
                echo ""
                echo "Environment variables:"
                echo "  BOOTSTRAP_DIR      Installation directory"
                echo ""
                echo "Examples:"
                echo "  curl -fsSL https://smyk.la | bash -s -- --yes"
                echo "  curl -fsSL https://smyk.la | bash -s -- --dir ~/dotfiles"
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                echo "Use --help for usage information"
                exit 1
                ;;
        esac
    done
}

main() {
    parse_args "$@"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "bartsmykla's dotfiles bootstrap"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Prerequisites
    check_macos
    check_internet
    check_git

    # Core setup
    install_homebrew
    clone_repository
    setup_age_key
    configure_git_filters

    # Installation
    install_dependencies

    # Note: Dotfiles are deployed via nix and home-manager
    # Run: home-manager switch --flake $DOTFILES_PATH/nix#home-bart

    # Plugins and hooks
    install_vim_plugins
    install_tmux_plugins
    install_git_hooks

    # Verification
    run_verification

    # Done
    print_success_message
}

main "$@"
