{ config, ... }:

{
  home.sessionPath = [ "$HOME/.local/bin" ];

  home.file.".local/bin/python3" = {
    source = config.lib.file.mkOutOfStoreSymlink "/opt/homebrew/bin/python3";
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
