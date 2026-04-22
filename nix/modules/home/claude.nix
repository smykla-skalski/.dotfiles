# Claude Code configuration
#
# Manages Claude Code config files:
# - CLAUDE.md.default, settings.json.default, statusline.sh — defaults from ./claude/
# - CLAUDE.md — user-editable file seeded from CLAUDE.md.default by activation
#
# Claude Code owns `installed_plugins.json` and `known_marketplaces.json`
# directly inside `~/.claude/`. They must not be managed here because the
# previous sops-nix path placed them under $DARWIN_USER_TEMP_DIR, which macOS
# periodically purges — installed plugins and marketplaces vanished across
# reboots.
#
# To update settings.json:
# 1. Edit ~/.claude/settings.json with your changes
# 2. Copy to: nix/modules/home/claude/settings.json
# 3. Run: hms
{ config, lib, pkgs, ... }:

let
  claudeMdTemplate = ./claude/CLAUDE.md;

  # Read the settings.json template and substitute BASH_ENV path
  settingsTemplate = builtins.readFile ./claude/settings.json;
  settingsJson = builtins.replaceStrings
    [ "/Users/bart.smykla@konghq.com/.bash_env" ]
    [ "${config.home.homeDirectory}/.bash_env" ]
    settingsTemplate;
in
{
  # Create ~/.claude directory
  home.file.".claude/.keep".text = "";

  # Create settings.json.default from template
  # Copy this to settings.json if you want to reset to defaults
  home.file.".claude/settings.json.default".text = settingsJson;

  # Keep the canonical CLAUDE.md template available for manual resets,
  # but do not manage ~/.claude/CLAUDE.md directly so tools can edit it.
  home.file.".claude/CLAUDE.md.default" = {
    source = claudeMdTemplate;
    force = true;
  };

  # Statusline scripts
  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ./claude/statusline.sh;
    force = true;
  };

  # Seed ~/.claude/CLAUDE.md from the managed default if missing, and migrate the
  # old Nix-managed symlink to a regular editable file on the first switch.
  home.activation.installEditableClaudeMd = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    claude_md="$HOME/.claude/CLAUDE.md"
    claude_md_default="${claudeMdTemplate}"

    if [ ! -e "$claude_md_default" ]; then
      echo "Skipping CLAUDE.md install: missing template $claude_md_default"
    elif [ -L "$claude_md" ]; then
      tmp_file="$(mktemp "${TMPDIR:-/tmp}/claude-md.XXXXXX")"
      cat "$claude_md" > "$tmp_file"
      chmod 600 "$tmp_file"
      rm -f "$claude_md"
      mv "$tmp_file" "$claude_md"
      echo "Migrated ~/.claude/CLAUDE.md from Home Manager symlink to editable file"
    elif [ ! -e "$claude_md" ]; then
      install -m 600 "$claude_md_default" "$claude_md"
      echo "Seeded editable ~/.claude/CLAUDE.md from managed default"
    fi
  '';

  # Clean up stale symlinks left behind by the old sops-managed layout so that
  # Claude Code can create real files in ~/.claude/. The symlink targets live
  # in $DARWIN_USER_TEMP_DIR, which macOS purges periodically, leaving broken
  # links that prevent Claude from persisting plugin registrations.
  home.activation.removeLegacyClaudePluginSymlinks = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    for name in installed_plugins.json known_marketplaces.json; do
      target="$HOME/.claude/$name"
      if [ -L "$target" ]; then
        rm -f "$target"
        echo "Removed legacy ~/.claude/$name symlink"
      fi
    done
  '';
}
