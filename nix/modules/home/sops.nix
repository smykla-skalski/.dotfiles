# Sops-nix secrets management for home-manager
#
# Uses the existing chezmoi age key for decryption.
# Secrets are decrypted at activation time and stored in the user's runtime dir.
#
# Edit secrets: SOPS_AGE_KEY_FILE=~/.config/chezmoi/key.txt sops nix/secrets/secrets.yaml
{ config, lib, pkgs, ... }:

{
  # Install sops CLI for editing secrets
  home.packages = [ pkgs.sops ];

  sops = {
    # Use the existing chezmoi age key
    age.keyFile = "${config.home.homeDirectory}/.config/chezmoi/key.txt";

    # Default secrets file location (relative to flake root)
    defaultSopsFile = ../../secrets/secrets.yaml;

    # Secrets configuration
    # Each secret becomes available at /run/user/<uid>/secrets/<name> or custom path
    secrets = {
      # K9s configuration
      "k9s/config" = {
        path = "%r/secrets/k9s-config.yaml";
      };

      # Exercism user config (contains API token)
      "exercism/user" = {
        path = "%r/secrets/exercism-user.json";
      };

      # Claude Code configuration
      "claude/claude_md" = {
        path = "%r/secrets/claude-CLAUDE.md";
      };

      "claude/installed_plugins" = {
        path = "%r/secrets/claude-installed_plugins.json";
      };

      "claude/known_marketplaces" = {
        path = "%r/secrets/claude-known_marketplaces.json";
      };
    };
  };
}
