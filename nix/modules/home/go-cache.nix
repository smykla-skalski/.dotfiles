# Daily trim of Go build and golangci-lint caches.
#
# Go only drops cache entries unused for 5 days and has no size cap, so
# agent-heavy days (race/cover/cross builds across many worktrees) can add
# tens of GB before its own trim runs. Go refreshes an entry's mtime when it
# is used, so deleting entries untouched for 2 days is safe during builds.
{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  trim = pkgs.writeShellScript "go-cache-trim" ''
    set -u
    # Shared caches plus stray per-worktree ones (e.g. GOCACHE=$PWD/bin/.cache/go-build).
    for dir in "${home}/Library/Caches/go-build" "${home}/Library/Caches/golangci-lint"; do
      [ -d "$dir" ] && /usr/bin/find "$dir" -type f -mtime +2 -delete
    done
    for root in /Users/Shared/codex-home/worktrees "${home}/orca/workspaces" "${home}/Projects"; do
      [ -d "$root" ] || continue
      /usr/bin/find "$root" -maxdepth 6 -type d \( -name node_modules -o -name .git \) -prune -o \
        -type d -path '*/.cache/go-build' -print 2>/dev/null |
        while IFS= read -r dir; do /usr/bin/find "$dir" -type f -mtime +2 -delete; done
    done
  '';
in {
  launchd.agents.go-cache-trim = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = ["${trim}"];
      StartCalendarInterval = [
        {
          Hour = 4;
          Minute = 0;
        }
      ];
      RunAtLoad = true;
      ProcessType = "Background";
      LowPriorityIO = true;
      Nice = 10;
      StandardOutPath = "${home}/Library/Logs/go-cache-trim.log";
      StandardErrorPath = "${home}/Library/Logs/go-cache-trim.log";
    };
  };
}
