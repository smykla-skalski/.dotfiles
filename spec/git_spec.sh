#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance

Describe 'Git configuration'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        export NIX_FLAKE="${DOTFILES_PATH}/nix/flake.nix"
    }
    Before 'setup'

    It 'selects SSH signing instead of the legacy Home Manager default'
        When call grep -qF 'signing.format = "ssh";' "${NIX_FLAKE}"
        The status should be success
    End
End
