#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance

Describe 'Ghostty configuration'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export GHOSTTY_MODULE="${DOTFILES_PATH}/nix/modules/home/ghostty.nix"
    }
    Before 'setup'

    It 'uses non-native fullscreen to avoid the macOS native restoration regression'
        When call grep -qF 'fullscreen = "non-native";' "${GHOSTTY_MODULE}"
        The status should be success
    End

    It 'does not configure the Linux-only tab bar setting'
        When call grep -qF 'window-show-tab-bar' "${GHOSTTY_MODULE}"
        The status should be failure
    End

    It 'does not keep a no-op cell width adjustment'
        When call grep -qF 'adjust-cell-width = 0;' "${GHOSTTY_MODULE}"
        The status should be failure
    End
End
