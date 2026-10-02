{ config, ... }:

{
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file.".local/bin/python3" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/python3";
    force = true;
  };

  # Shell activation and mise's shims run mise from this path. Point it at the
  # Homebrew mise from homebrew.nix, which stays updated, so a standalone copy
  # from `curl mise.run | sh` can't shadow it and go stale.
  home.file.".local/bin/mise" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/mise";
    force = true;
  };

  home.file.".local/bin/orca-codex-status-hook" = {
    source = ../../../helper_scripts/orca-codex-status-hook;
    executable = true;
    force = true;
  };

  home.file.".local/bin/orca-mobile-pair-cloudflare" = {
    source = ../../../helper_scripts/orca-mobile-pair-cloudflare;
    executable = true;
    force = true;
  };
}
