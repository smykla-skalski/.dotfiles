# Claude Code configuration
#
# Manages Claude Code config files via sops-nix secrets.
# The secrets are decrypted at runtime and symlinked to ~/.claude/
#
# Edit secrets: SOPS_AGE_KEY_FILE=~/.config/chezmoi/key.txt sops nix/secrets/secrets.yaml
{ config, lib, pkgs, ... }:

let
  # Get the Darwin temp directory for sops secrets
  # sops-nix on Darwin uses $DARWIN_USER_TEMP_DIR/secrets/
  secretsDir = ''$(getconf DARWIN_USER_TEMP_DIR)/secrets'';
in
{
  # Create ~/.claude directory
  home.file.".claude/.keep".text = "";

  # Symlink CLAUDE.md from sops secret
  home.activation.linkClaudeSecrets = lib.hm.dag.entryAfter [ "writeBoundary" "sops-nix" ] ''
    # Get the actual temp directory
    TEMP_DIR="$(getconf DARWIN_USER_TEMP_DIR)"

    # Create symlinks for Claude secrets
    if [ -f "$TEMP_DIR/secrets/claude-CLAUDE.md" ]; then
      ln -sf "$TEMP_DIR/secrets/claude-CLAUDE.md" "$HOME/.claude/CLAUDE.md"
      echo "Linked CLAUDE.md from sops secret"
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
