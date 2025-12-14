# Fish shell Python environment functions
{ ... }:

{
  programs.fish.functions = {
    # Auto-detect Python projects and set up direnv
    # Triggered on directory change via interactiveShellInit
    __auto_python_env = {
      description = "Auto-detect Python projects and create .envrc";
      body = ''
        # Skip if not in a real directory
        test -d "$PWD" || return

        # Check for Python project indicators
        set -l has_requirements (test -f requirements.txt && echo yes)
        set -l has_pyproject (test -f pyproject.toml && echo yes)

        # Exit if no Python project detected
        test -z "$has_requirements" -a -z "$has_pyproject" && return

        # Exit if .envrc already exists
        test -f .envrc && return

        # Create .envrc
        echo "use_python_env" > .envrc

        # Add to git exclude if this is a git repo
        if test -e .git
          __add_to_git_excludes .envrc
          __add_to_git_excludes .direnv/
        end

        # Allow direnv (suppress output)
        direnv allow 2>/dev/null
      '';
    };

    # Add a pattern to .git/info/exclude for repo and all worktrees
    __add_to_git_excludes = {
      description = "Add pattern to git exclude for repo and all worktrees";
      body = ''
        set -l pattern $argv[1]
        test -z "$pattern" && return 1

        # Get the git directory (handles both regular repos and worktrees)
        set -l git_dir (git rev-parse --git-dir 2>/dev/null)
        test -z "$git_dir" && return 1

        # Get the common git directory (main repo's .git for worktrees)
        set -l git_common_dir (git rev-parse --git-common-dir 2>/dev/null)
        test -z "$git_common_dir" && set git_common_dir $git_dir

        # Function to add pattern to an exclude file
        function __add_pattern_to_exclude
          set -l exclude_file $argv[1]
          set -l pat $argv[2]

          # Create info directory if needed
          set -l info_dir (dirname $exclude_file)
          test -d $info_dir || mkdir -p $info_dir

          # Create exclude file if needed
          test -f $exclude_file || touch $exclude_file

          # Add pattern if not already present
          if not grep -qxF $pat $exclude_file 2>/dev/null
            echo $pat >> $exclude_file
          end
        end

        # Add to current git dir's exclude
        __add_pattern_to_exclude "$git_dir/info/exclude" $pattern

        # If we're in a worktree, also add to main repo
        if test "$git_dir" != "$git_common_dir"
          __add_pattern_to_exclude "$git_common_dir/info/exclude" $pattern
        end

        # Add to all worktrees
        set -l worktrees_dir "$git_common_dir/worktrees"
        if test -d $worktrees_dir
          for wt in $worktrees_dir/*/
            set -l wt_exclude "$wt/info/exclude"
            __add_pattern_to_exclude $wt_exclude $pattern
          end
        end

        # Clean up the inner function
        functions -e __add_pattern_to_exclude
      '';
    };
  };

  # Hook into directory changes
  programs.fish.interactiveShellInit = ''
    # Auto-detect Python projects on directory change
    function __on_pwd_change --on-variable PWD
      __auto_python_env
    end
  '';
}
