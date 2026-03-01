# Sops-nix secrets management for home-manager
#
# Uses the age key for decryption.
# Secrets are decrypted at activation time and stored in the user's runtime dir.
#
# Edit secrets: SOPS_AGE_KEY_FILE=~/.config/age/key.txt sops nix/secrets/secrets.yaml
{ config, lib, pkgs, ... }:

{
  # Install sops CLI for editing secrets
  home.packages = [ pkgs.sops ];

  sops = {
    # Use the age key for secrets decryption
    age.keyFile = "${config.home.homeDirectory}/.config/age/key.txt";

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

      # Claude Code configuration (CLAUDE.md moved to plain file in claude.nix)
      "claude/installed_plugins" = {
        path = "%r/secrets/claude-installed_plugins.json";
      };

      "claude/known_marketplaces" = {
        path = "%r/secrets/claude-known_marketplaces.json";
      };
    };
  };
}
