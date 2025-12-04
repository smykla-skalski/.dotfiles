#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Bootstrap Script Tests
#
# PURPOSE:
#   Test docs/bootstrap.sh functionality and configuration
#
# WHAT'S TESTED:
#   - Script exists and is executable
#   - Script has valid bash syntax
#   - Help output includes all required options
#   - Configuration defaults are set correctly
#   - Command-line arguments are parsed properly
#   - Environment variables work as expected
#
# HOW TO RUN:
#   shellspec spec/bootstrap_spec.sh
#   OR
#   task test:shellspec
#
# REFERENCE:
#   https://shellspec.info/

Describe 'Bootstrap Script'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export BOOTSTRAP_SCRIPT="${DOTFILES_PATH}/docs/bootstrap.sh"
        cd "${DOTFILES_PATH}" || return 1
    }
    Before 'setup'

    Describe 'File properties'
        It 'exists'
            The file "${BOOTSTRAP_SCRIPT}" should be exist
        End

        It 'is executable'
            The file "${BOOTSTRAP_SCRIPT}" should be executable
        End

        It 'has bash shebang'
            When call head -n 1 "${BOOTSTRAP_SCRIPT}"
            The output should include "#!/usr/bin/env bash"
        End

        It 'has valid bash syntax'
            When call bash -n "${BOOTSTRAP_SCRIPT}"
            The status should be success
        End

        It 'passes shellcheck'
            Skip if "shellcheck not available" command -v shellcheck
            When call shellcheck "${BOOTSTRAP_SCRIPT}"
            The status should be success
        End
    End

    Describe 'Help output'
        It 'shows help with --help flag'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The status should be success
            The output should include "Bootstrap script for bartsmykla's dotfiles"
        End

        It 'shows help with -h flag'
            When call bash "${BOOTSTRAP_SCRIPT}" -h
            The status should be success
            The output should include "Usage:"
        End

        It 'includes --yes option in help'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The output should include "--yes, -y"
            The output should include "Skip confirmation prompts"
        End

        It 'includes --dir option in help'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The output should include "--dir DIRECTORY"
            The output should include "Installation directory"
        End

        It 'includes --help option in help'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The output should include "--help, -h"
        End

        It 'includes BOOTSTRAP_DIR in help'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The output should include "BOOTSTRAP_DIR"
        End

        It 'includes usage examples'
            When call bash "${BOOTSTRAP_SCRIPT}" --help
            The output should include "Examples:"
            The output should include "curl -fsSL https://smyk.la"
        End
    End

    Describe 'Configuration defaults'
        It 'has default repository organization'
            When call grep -o 'REPO_ORG="[^"]*"' "${BOOTSTRAP_SCRIPT}"
            The output should include 'REPO_ORG="bartsmykla"'
        End

        It 'has default repository name'
            When call grep -o 'REPO_NAME="[^"]*"' "${BOOTSTRAP_SCRIPT}"
            The output should include 'REPO_NAME=".dotfiles"'
        End

        It 'has GitHub repository URL'
            When call grep -o 'REPO_URL="[^"]*"' "${BOOTSTRAP_SCRIPT}"
            The output should include "github.com"
        End

        It 'has age key path configuration'
            When call grep -o 'AGE_KEY_PATH="[^"]*"' "${BOOTSTRAP_SCRIPT}"
            The output should include ".config/age/key.txt"
        End

        It 'has 1Password age key ID'
            When call grep -o 'AGE_KEY_OP_ID="[^"]*"' "${BOOTSTRAP_SCRIPT}"
            The output should include "dyhxf4wgavxqwt23wbsl5my2m"
        End

        It 'has default installation directory with environment variable fallback'
            When call grep 'BOOTSTRAP_DIR=' "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should include "Projects/github.com"
        End
    End

    Describe 'Helper functions'
        It 'has log_info function'
            When call grep -c "^log_info()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has log_success function'
            When call grep -c "^log_success()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has log_warn function'
            When call grep -c "^log_warn()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has log_error function'
            When call grep -c "^log_error()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has die function'
            When call grep -c "^die()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has prompt_yes_no function'
            When call grep -c "^prompt_yes_no()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has command_exists function'
            When call grep -c "^command_exists()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End
    End

    Describe 'Main installation functions'
        It 'has check_macos function'
            When call grep -c "^check_macos()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has check_internet function'
            When call grep -c "^check_internet()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has check_git function'
            When call grep -c "^check_git()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has install_homebrew function'
            When call grep -c "^install_homebrew()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has clone_repository function'
            When call grep -c "^clone_repository()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has setup_age_key function'
            When call grep -c "^setup_age_key()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has configure_git_filters function'
            When call grep -c "^configure_git_filters()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has install_dependencies function'
            When call grep -c "^install_dependencies()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has install_vim_plugins function'
            When call grep -c "^install_vim_plugins()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has install_tmux_plugins function'
            When call grep -c "^install_tmux_plugins()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has install_git_hooks function'
            When call grep -c "^install_git_hooks()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has run_verification function'
            When call grep -c "^run_verification()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has print_success_message function'
            When call grep -c "^print_success_message()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has parse_args function'
            When call grep -c "^parse_args()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'has main function'
            When call grep -c "^main()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End
    End

    Describe 'Script structure'
        It 'uses set -euo pipefail for error handling'
            When call grep "set -euo pipefail" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'has shellcheck disable comment for expected behavior'
            When call grep "shellcheck disable=SC2310" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'has RED color definition'
            When call grep "readonly RED=" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'has GREEN color definition'
            When call grep "readonly GREEN=" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'has YELLOW color definition'
            When call grep "readonly YELLOW=" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'has BLUE color definition'
            When call grep "readonly BLUE=" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'calls parse_args in main'
            When call grep "parse_args" "${BOOTSTRAP_SCRIPT}"
            The output should include 'parse_args "$@"'
        End

        It 'calls main with arguments at end of script'
            When call tail -1 "${BOOTSTRAP_SCRIPT}"
            The output should include 'main "$@"'
        End
    End

    Describe 'Error handling'
        It 'rejects unknown options'
            When run bash "${BOOTSTRAP_SCRIPT}" --invalid-option
            The status should be failure
            The stderr should include "Unknown option"
            The stdout should include "Use --help"
        End

        It 'suggests --help on unknown option'
            When run bash "${BOOTSTRAP_SCRIPT}" --invalid-option
            The status should be failure
            The stdout should include "Use --help for usage information"
            The stderr should be present
        End

        It 'rejects --dir without value'
            When run bash "${BOOTSTRAP_SCRIPT}" --dir
            The status should be failure
            The stderr should include "--dir requires a value"
        End

        It 'rejects --dir with flag as value'
            When run bash "${BOOTSTRAP_SCRIPT}" --dir --yes
            The status should be failure
            The stderr should include "--dir requires a value"
        End
    End

    Describe 'Clone repository function'
        It 'creates parent directory with mkdir -p'
            When call grep 'mkdir -p.*dirname.*TARGET_DIR' "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'uses TARGET_DIR variable for cloning'
            When call grep 'git clone.*TARGET_DIR' "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End
    End

    Describe 'Documentation'
        It 'has usage comment at top'
            When call head -10 "${BOOTSTRAP_SCRIPT}"
            The output should include "Usage:"
        End

        It 'shows curl command in usage'
            When call head -10 "${BOOTSTRAP_SCRIPT}"
            The output should include "curl -fsSL https://smyk.la"
        End

        It 'shows --dir option in usage examples'
            When call head -10 "${BOOTSTRAP_SCRIPT}"
            The output should include "--dir"
        End
    End

    Describe 'Age key setup'
        It 'has improved age key instructions'
            When call grep -A 2 "Please paste your age key" "${BOOTSTRAP_SCRIPT}"
            The output should include "then press Ctrl-D (without pressing Enter first)"
        End

        It 'has trim helper function'
            When call grep -c "^trim()" "${BOOTSTRAP_SCRIPT}"
            The output should not equal "0"
        End

        It 'trims whitespace from age key input'
            When call grep "key_content=.*trim" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'validates age key format'
            When call grep "AGE-SECRET-KEY-" "${BOOTSTRAP_SCRIPT}"
            The status should be success
            The output should be present
        End

        It 'fails fast with --yes flag when age key unavailable'
            When call grep -A 3 "Fallback to manual paste" "${BOOTSTRAP_SCRIPT}"
            The output should include "YES_FLAG"
            The output should include "die"
        End
    End

    Describe 'Integration tests for --yes flag fail-fast behavior'
        setup_test_env() {
            # Create temporary test directory
            # shellcheck disable=SC2154  # SHELLSPEC_TMPBASE is a ShellSpec built-in variable
            export TEST_HOME="${SHELLSPEC_TMPBASE}/test-home"
            export HOME="${TEST_HOME}"
            mkdir -p "${TEST_HOME}"

            # Mock git to return no config
            # shellcheck disable=SC2329  # Function is invoked indirectly via export -f
            git() {
                if [[ "$*" == *"config"* ]]; then
                    return 1
                fi
                command git "$@"
            }
            export -f git

            # Mock op command to simulate 1Password unavailable
            # shellcheck disable=SC2329  # Function is invoked indirectly via export -f
            op() {
                return 1
            }
            export -f op

            # Mock ping to always succeed (avoid flaky network checks in CI)
            # shellcheck disable=SC2329  # Function is invoked indirectly via export -f
            ping() {
                return 0
            }
            export -f ping
        }

        cleanup_test_env() {
            # Restore original HOME
            unset TEST_HOME
            unset -f git 2>/dev/null || true
            unset -f op 2>/dev/null || true
            unset -f ping 2>/dev/null || true
        }

        Before 'setup_test_env'
        After 'cleanup_test_env'

        It 'fails immediately with --yes when age key is unavailable'
            Skip if "Test requires macOS" test "$(uname)" != "Darwin"

            When run bash "${BOOTSTRAP_SCRIPT}" --yes --dir "${TEST_HOME}/.dotfiles"
            The status should be failure
            The stderr should include "Age key is required"
            The output should include "bartsmykla's dotfiles bootstrap"
        End
    End

    Describe 'Trim function behavior'
        # Define trim function directly for testing
        # This is the same implementation as in bootstrap.sh
        setup_trim() {
            # shellcheck disable=SC2329  # Function is invoked indirectly via ShellSpec test framework
            trim() {
                local var="$1"
                # Remove leading whitespace
                var="${var#"${var%%[![:space:]]*}"}"
                # Remove trailing whitespace
                var="${var%"${var##*[![:space:]]}"}"
                echo "${var}"
            }
        }

        Before 'setup_trim'

        It 'trims leading whitespace'
            When call trim "  hello"
            The output should equal "hello"
        End

        It 'trims trailing whitespace'
            When call trim "hello  "
            The output should equal "hello"
        End

        It 'trims both leading and trailing whitespace'
            When call trim "  hello  "
            The output should equal "hello"
        End

        It 'preserves internal whitespace'
            When call trim "  hello world  "
            The output should equal "hello world"
        End

        It 'handles empty string'
            When call trim ""
            The output should equal ""
        End

        It 'handles string with only whitespace'
            When call trim "   "
            The output should equal ""
        End
    End
End
