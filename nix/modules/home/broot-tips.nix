# Broot Tips Fish Function - Nix Module
#
# This module creates a Fish function wrapper for broot that shows
# random tips to help you learn new shortcuts through repetition.
#
# Installation:
#   1. Copy to nix/modules/home/broot-tips.nix
#   2. Import in your home.nix
#   3. Run: home-manager switch
#
# The function wraps the `br` command and shows tips 50% of the time.

{ config, lib, pkgs, ... }:

{
  programs.fish = {
    functions = {
      br = {
        description = "Broot wrapper with random learning tips";
        body = ''
          # Tips focusing on NEW shortcuts to learn
          set -l tips \
              "💡 TIP: Use Ctrl-j/k for vim-style navigation (NEW!)" \
              "💡 TIP: Press F5/F6 for Norton Commander copy/move (NEW!)" \
              "💡 TIP: Type 'gs' for interactive git status view (NEW!)" \
              "💡 TIP: Ctrl-s triggers total search for large dirs (NEW!)" \
              "💡 TIP: Use 'md <name>' to create directories (NEW!)" \
              "💡 TIP: 'gtr' jumps to git repository root (NEW!)" \
              "💡 TIP: Alt-g toggles git status filter (NEW!)" \
              "💡 TIP: Ctrl-p goes to parent directory (NEW!)" \
              "💡 TIP: Type 'r' to reveal file in Finder (NEW!)" \
              "💡 TIP: Ctrl-u/d for page up/down vim-style (NEW!)" \
              "💡 TIP: Ctrl-home goes to home directory (NEW!)" \
              "💡 TIP: Default flags are now -ghc (git/hidden/counts)" \
              "💡 TIP: Press ? in broot to see ALL shortcuts!" \
              "💡 TIP: Use Ctrl-→ for preview panel" \
              "💡 TIP: Type 'bk' for full cheatsheet (gocheat)"

          # Select random tip
          set -l random_index (random 1 (count $tips))
          set -l random_tip $tips[$random_index]

          # Show tip 50% of the time (adjust percentage as needed)
          # To change frequency: modify the number (e.g., 30 for 30%, 70 for 70%)
          if test (random 1 100) -le 50
              set_color yellow
              echo $random_tip
              set_color normal
              # Brief pause so tip is readable
              sleep 0.4
          end

          # Call the actual broot command with all arguments
          command broot $argv
        '';
      };
    };
  };
}
