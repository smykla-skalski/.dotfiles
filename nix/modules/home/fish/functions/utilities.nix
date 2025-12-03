# Fish shell utility functions
{ ... }:

{
  programs.fish.functions = {
    mkd = {
      description = "Create directory and cd into it";
      body = "mkdir -p $argv && cd $argv";
    };

    up-or-search = {
      description = "Move up in history or search";
      body = ''
        if commandline --search-mode
          commandline -f history-search-backward
          return
        end

        if commandline --paging-mode
          commandline -f up-line
          return
        end

        set -l lineno (commandline -L)
        if test $lineno -gt 1
          commandline -f up-line
        else
          commandline -f history-search-backward
        end
      '';
    };

    link-dotfile = {
      description = "Create symlink for dotfile";
      body = ''
        if test (count $argv) -ne 2
          echo "Usage: link-dotfile <source> <target>" >&2
          return 1
        end
        ln -sf $argv[1] $argv[2]
      '';
    };

    fish_title = {
      description = "Custom window title format";
      body = ''
        # Skip title updates for interactive apps that manage their own titles
        set -l command (status current-command)
        if test "$command" = fish
          set command
        end

        # Use argv if provided (e.g., from fg command)
        if set -q argv[1]
          set command $argv[1]
        end

        # Don't set title for apps that control their own (editors, TUIs, etc)
        # They'll set it themselves and we'll reset it when they exit
        set -l skip_apps claude vim nvim emacs nano less more man ssh
        if contains "$command" $skip_apps
          return
        end

        # Get the last two path components for cleaner display
        set -l pwd_parts (string split / (pwd))
        set -l num_parts (count $pwd_parts)
        set -l path

        if test $num_parts -ge 2
          set path "$pwd_parts[-2]/$pwd_parts[-1]"
        else
          set path $pwd_parts[-1]
        end

        # Format: "path ~ command" or just "path" if no command
        if test -n "$command"
          echo "$path ~ $command"
        else
          echo "$path"
        end
      '';
    };
  };
}
