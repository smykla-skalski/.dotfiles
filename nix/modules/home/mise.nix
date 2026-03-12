# Mise tool version manager configuration
#
# Keep the declarative mise config in Home Manager, but use an external binary
# so `home-manager switch` never has to build mise from source.
{ pkgs, ... }:

let
  miseConfig = {
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
in
{
  # Written to $XDG_CONFIG_HOME/mise/config.toml
  # Tool versions are read from mise/config.toml and managed by Renovate
  xdg.configFile."mise/config.toml".source =
    (pkgs.formats.toml { }).generate "mise-config.toml" miseConfig;
}
