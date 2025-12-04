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

    # Enable fish shell integration (full activation with hook-env per prompt)
    enableFishIntegration = true;

    # Global tool configuration
    # Written to $XDG_CONFIG_HOME/mise/config.toml
    globalConfig = {
      tools = {
        actionlint = "1.7.8";
        age = "1.2.1";
        cosign = "3.0.2";
        go = "1.25.4";
        golangci-lint = "2.6.2";
        "npm:markdownlint-cli" = "0.45.0";
        pnpm = "10.22.0";
        ruby = "3.4.7";
        shellcheck = "0.11.0";
        task = "3.45.4";
        tflint = "0.60.0";
      };

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
