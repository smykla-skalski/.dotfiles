# Mise tool version manager configuration
#
# Keep the declarative mise config in Home Manager, but use an external binary
# so `home-manager switch` never has to build mise from source.
{ pkgs, ... }:

let
  misePackage = pkgs.writeShellScriptBin "mise" ''
    for candidate in "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
      if [ -x "$candidate" ]; then
        exec "$candidate" "$@"
      fi
    done

    echo "mise is managed outside Nix. Install it with the official installer or Homebrew." >&2
    exit 1
  '';

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
  home.packages = [ misePackage ];

  # Written to $XDG_CONFIG_HOME/mise/config.toml
  # Tool versions are read from mise/config.toml and managed by Renovate
  xdg.configFile."mise/config.toml".source =
    (pkgs.formats.toml { }).generate "mise-config.toml" miseConfig;
}
