# Claude Code configuration
#
# Manages Claude Code config files:
# - CLAUDE.md, settings.json, statusline.sh — plain files in ./claude/
# - installed_plugins.json, known_marketplaces.json — sops-nix secrets
#
# To update settings.json:
# 1. Edit ~/.claude/settings.json with your changes
# 2. Copy to: nix/modules/home/claude/settings.json
# 3. Run: hms
{ config, lib, pkgs, ... }:

let
  # Get the Darwin temp directory for sops secrets
  # sops-nix on Darwin uses $DARWIN_USER_TEMP_DIR/secrets/
  secretsDir = ''$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)/secrets'';

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

  # CLAUDE.md — plain file (not sops-encrypted)
  home.file.".claude/CLAUDE.md" = {
    source = ./claude/CLAUDE.md;
    force = true;
  };

  # Statusline scripts
  home.file.".claude/statusline.sh" = {
    executable = true;
    source = ./claude/statusline.sh;
    force = true;
  };

  # Symlink remaining Claude secrets from sops
  home.activation.linkClaudeSecrets = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    # Get the actual temp directory
    if [ -x /usr/bin/getconf ]; then
      TEMP_DIR="$(/usr/bin/getconf DARWIN_USER_TEMP_DIR 2>/dev/null)"
    else
      TEMP_DIR=""
    fi

    if [ -f "$TEMP_DIR/secrets/claude-installed_plugins.json" ]; then
      ln -sf "$TEMP_DIR/secrets/claude-installed_plugins.json" "$HOME/.claude/installed_plugins.json"
      echo "Linked installed_plugins.json from sops secret"
    fi

    if [ -f "$TEMP_DIR/secrets/claude-known_marketplaces.json" ]; then
      ln -sf "$TEMP_DIR/secrets/claude-known_marketplaces.json" "$HOME/.claude/known_marketplaces.json"
      echo "Linked known_marketplaces.json from sops secret"
    fi
  '';
}
