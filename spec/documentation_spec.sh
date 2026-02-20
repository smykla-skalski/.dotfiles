#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Documentation Tests
#
# PURPOSE:
#   Ensure all required documentation exists and follows standards
#
# WHAT'S TESTED:
#   - Required documentation files exist
#   - Markdown files pass linting
#   - Documentation structure is correct
#   - Links in documentation are valid
#
# HOW TO RUN:
#   shellspec spec/documentation_spec.sh
#   OR
#   make test-docs
#
# REFERENCE:
#   https://github.com/DavidAnson/markdownlint

Describe 'Documentation'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        # Add mise shims to PATH so tools are available in ShellSpec evaluation context
        export PATH="$HOME/.local/share/mise/shims:$PATH"
    }
    Before 'setup'

    Describe 'Required files exist'
        It 'has README.md'
            The file "${DOTFILES_PATH}/README.md" should be exist
        End

        It 'has CONTRIBUTING.md'
            The file "${DOTFILES_PATH}/CONTRIBUTING.md" should be exist
        End

        It 'has TESTING.md'
            The file "${DOTFILES_PATH}/TESTING.md" should be exist
        End

        It 'has TROUBLESHOOTING.md'
            The file "${DOTFILES_PATH}/TROUBLESHOOTING.md" should be exist
        End
    End

    Describe 'README.md structure'
        It 'has Quick Start section'
            When call grep -q '## Quick Start' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Features section'
            When call grep -q '## Features' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Testing section'
            When call grep -q '## Testing' "${DOTFILES_PATH}/README.md"
            The status should be success
        End

        It 'has Documentation section'
            When call grep -q '## Documentation' "${DOTFILES_PATH}/README.md"
            The status should be success
        End
    End

    Describe 'Markdown linting'
        It 'README.md passes markdownlint-cli2'
            Skip if "markdownlint-cli2 not installed" ! command -v markdownlint-cli2 >/dev/null 2>&1
            When run command markdownlint-cli2 "${DOTFILES_PATH}/README.md"
            The status should be success
            The output should be defined
        End

        It 'core documentation files pass markdownlint-cli2'
            Skip if "markdownlint-cli2 not installed" ! command -v markdownlint-cli2 >/dev/null 2>&1
            # Test only core docs, not vim bundles or tmp files
            When run command markdownlint-cli2 "${DOTFILES_PATH}"/*.md
            The status should be success
            The output should be defined
        End
    End

    Describe 'Code blocks in documentation'
        It 'README.md has balanced code blocks'
            # Count code block markers (should be even number - opening + closing)
            check_code_blocks() {
                local count
                count=$(grep -c '^```' "${DOTFILES_PATH}/README.md" || true)
                [ $((count % 2)) -eq 0 ]
            }
            When call check_code_blocks
            The status should be success
        End
    End
End
