#!/usr/bin/env bash
# shellcheck disable=SC2292  # ShellSpec uses [ ] intentionally for POSIX compliance

Describe 'Age git filters'
    setup() {
        # shellcheck disable=SC2296  # $SHELLSPEC_PROJECT_ROOT is a ShellSpec built-in variable
        export DOTFILES_PATH="${SHELLSPEC_PROJECT_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
        # Git hooks run this suite with GIT_DIR and friends pointing at this
        # repository, and git init under them reinitializes it instead of
        # creating the throwaway repository below.
        # shellcheck disable=SC2046  # one variable name per word
        unset $(git rev-parse --local-env-vars)
        TEST_DIR="$(mktemp -d)"
    }
    cleanup() {
        rm -rf "${TEST_DIR}"
    }
    Before 'setup'
    After 'cleanup'

    It 'populates the age cache of a new linked worktree'
        repo="${TEST_DIR}/repo"
        git init -q "${repo}"
        cp "${DOTFILES_PATH}/scripts/git-filters/age-cache-populate.sh" "${repo}/.git/"
        # Stands in for the smudge filter, so no age key is needed.
        printf '#!/usr/bin/env bash\ncat\n' >"${repo}/.git/age-smudge.sh"
        cp "${DOTFILES_PATH}/hooks/post-checkout" "${repo}/.git/hooks/"
        chmod +x "${repo}/.git/age-cache-populate.sh" "${repo}/.git/age-smudge.sh" "${repo}/.git/hooks/post-checkout"
        echo 'secret filter=age' >"${repo}/.gitattributes"
        echo 'value' >"${repo}/secret"
        git -C "${repo}" add .
        git -C "${repo}" -c user.name=spec -c user.email=spec@example.com -c commit.gpgsign=false \
            commit -q -m 'test(age): add a secret'
        git -C "${repo}" worktree add -q "${TEST_DIR}/worktree"
        When call ls "${repo}/.git/worktrees/worktree/age-cache"
        The output should not equal ''
    End
End
