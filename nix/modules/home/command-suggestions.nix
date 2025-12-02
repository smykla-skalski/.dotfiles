# Command Suggestions - Fish Function Wrappers
#
# Provides helpful suggestions when using legacy commands that have
# better alternatives in broot. Shows tips randomly to build awareness
# without being intrusive.
#
# Wraps: cd, ls, find, tree
# Suggests: br (broot) as a better alternative

{ config, lib, pkgs, ... }:

{
  programs.fish = {
    functions = {
      # Wrapper for 'cd' suggesting broot
      cd = {
        description = "cd with occasional broot suggestions";
        wraps = "cd";
        body = ''
          # Show suggestion 15% of the time for simple directory changes
          if test (count $argv) -eq 1; and test (random 1 100) -le 15
            set_color yellow
            echo "💡 TIP: Try 'br' for interactive navigation with fuzzy search!"
            set_color normal
            sleep 0.3
          end

          # Call the builtin cd command
          builtin cd $argv
        '';
      };

      # Wrapper for 'ls' suggesting broot
      ls = {
        description = "ls with occasional broot suggestions";
        body = ''
          # Show suggestion 10% of the time when ls is used without args (viewing current dir)
          if test (count $argv) -eq 0; and test (random 1 100) -le 10
            set_color yellow
            echo "💡 TIP: 'br' gives you an interactive tree view with search!"
            set_color normal
            sleep 0.3
          end

          # Call the actual ls command
          command ls $argv
        '';
      };

      # Wrapper for 'find' suggesting broot
      find = {
        description = "find with occasional broot suggestions";
        body = ''
          # Show suggestion 20% of the time when using find for files
          if test (random 1 100) -le 20
            set_color yellow
            echo "💡 TIP: 'br' has fuzzy search - just start typing! Try 'br -c <pattern>'"
            set_color normal
            sleep 0.3
          end

          # Call the actual find command
          command find $argv
        '';
      };

      # Wrapper for 'tree' suggesting broot
      tree = {
        description = "tree with occasional broot suggestions";
        body = ''
          # Show suggestion 25% of the time (tree users likely want interactive view)
          if test (random 1 100) -le 25
            set_color yellow
            echo "💡 TIP: 'br' is like tree but interactive with fuzzy search and file ops!"
            set_color normal
            sleep 0.3
          end

          # Call the actual tree command
          command tree $argv
        '';
      };

      # Wrapper for 'grep' suggesting broot content search
      grep = {
        description = "grep with occasional broot suggestions";
        body = ''
          # Show suggestion 10% of the time when grepping recursively
          if contains -- "-r" $argv; or contains -- "-R" $argv
            if test (random 1 100) -le 10
              set_color yellow
              echo "💡 TIP: In broot, type 'c/<pattern>' for content search!"
              set_color normal
              sleep 0.3
            end
          end

          # Call the actual grep command
          command grep $argv
        '';
      };
    };

    # Add helpful aliases that suggest using broot
    shellAliases = {
      # Create an alias that explains broot's fuzzy cd
      cdf = "echo '💡 Use: br <pattern> then Alt-Enter to cd there!' && false";
    };
  };
}
