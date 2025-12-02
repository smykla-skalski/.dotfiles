function _fzf_wrapper --description "Prepares some environment variables before executing fzf."
    # Make sure fzf uses fish to execute preview commands, some of which
    # are autoloaded fish functions so don't exist in other shells.
    # Use --function so that it doesn't clobber SHELL outside this function.
    set -f --export SHELL (command --search fish)

    # FZF_DEFAULT_OPTS is set in fish.nix interactiveShellInit
    # This wrapper just ensures SHELL is set correctly for preview commands

    fzf $argv
end
