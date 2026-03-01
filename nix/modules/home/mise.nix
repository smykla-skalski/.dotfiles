# Mise tool version manager configuration
#
# Migrated from chezmoi to home-manager programs.mise.
# Mise manages runtime versions (Go, Ruby, Node, etc.) in a declarative way.
#
# Note: As of Jan 2025, mise reads settings from config.toml under [settings],
# not from a separate settings.toml file. The globalConfig option handles this.
{ config, lib, pkgs, ... }:

{
  programs.mise = {
    enable = true;

    # Disable home-manager's bash integration since we manually configure it in bash.nix
    # This prevents duplicate activation and gives us full control over non-interactive shells
    enableBashIntegration = false;

    # Enable fish shell integration (full activation with hook-env per prompt)
    enableFishIntegration = true;

    # Global tool configuration
    # Written to $XDG_CONFIG_HOME/mise/config.toml
    #
    # Tool versions are read from mise/config.toml and managed by Renovate
    globalConfig = {
      tools = (builtins.fromTOML (builtins.readFile ./mise/config.toml)).tools;

      settings = {
        experimental = true;
        idiomatic_version_file_enable_tools = [ "ruby" ];
        auto_install = false;
        not_found_auto_install = false;
        auto_install_disable_tools = [
          "go:github.com/chrusty/protoc-gen-jsonschema/cmd/protoc-gen-jsonschema"
        ];
        fetch_remote_versions_cache = "24h";
        fetch_remote_versions_timeout = "2s";
        cache_prune_age = "90d";
        lockfile = true;
      };
    };
  };
}
