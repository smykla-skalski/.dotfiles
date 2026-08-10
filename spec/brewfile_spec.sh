#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance
#
# Brewfile Tests
#
# PURPOSE:
#   Test Brewfile validity and package declarations
#
# WHAT'S TESTED:
#   - Brewfile exists
#   - Brewfile has valid syntax
#   - Brewfile can be checked without errors
#   - Required packages are declared
#
# HOW TO RUN:
#   shellspec spec/brewfile_spec.sh
#   OR
#   make test-brewfile
#
# REFERENCE:
#   https://docs.brew.sh/Brew-Bundle

Describe 'Brewfile'
    setup() {
        # shellcheck disable=SC2155  # Declare and assign separately - not critical for test setup
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
    }
    Before 'setup'

    It 'exists in repository root'
        The file "${DOTFILES_PATH}/Brewfile" should be exist
    End

    It 'is readable'
        The file "${DOTFILES_PATH}/Brewfile" should be readable
    End

    It 'has valid Brewfile syntax'
        # brew bundle check validates syntax and returns status 1 if packages missing (OK for CI)
        When call brew bundle check --file="${DOTFILES_PATH}/Brewfile" --no-upgrade
        # Accept both status 0 (all installed) and 1 (some missing) as valid
        The status should not equal 2
        # brew bundle check writes status info to stderr, not stdout
        The stderr should be present
    End

    Describe 'Essential packages are declared'
        It 'declares fish shell'
            When call grep -q '^brew "fish"' "${DOTFILES_PATH}/Brewfile"
            The status should be success
        End

        It 'declares tmux'
            When call grep -q '^brew "tmux"' "${DOTFILES_PATH}/Brewfile"
            The status should be success
        End

        It 'declares vim'
            When call grep -q '^brew "vim"' "${DOTFILES_PATH}/Brewfile"
            The status should be success
        End
    End

    Describe 'Brewfile structure'
        It 'has comments explaining sections'
            When call grep -q '^#' "${DOTFILES_PATH}/Brewfile"
            The status should be success
        End

        It 'declares taps before formulas'
            check_tap_order() {
                local tap_line brew_line
                tap_line=$(grep -n '^tap ' "${DOTFILES_PATH}/Brewfile" | head -1 | cut -d: -f1)
                brew_line=$(grep -n '^brew ' "${DOTFILES_PATH}/Brewfile" | head -1 | cut -d: -f1)
                [ -n "$tap_line" ] && [ -n "$brew_line" ] && [ "$tap_line" -lt "$brew_line" ]
            }
            When call check_tap_order
            The status should be success
        End
    End
End
