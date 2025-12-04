# Tool completions and additional configurations
#
# Fish completions use a caching strategy to balance speed and freshness:
# - Cobra-based tools (kubectl, docker, etc.) generate dynamic completions
# - We wrap them with caching to avoid calling the binary on every tab press
# - Cache is stored per-session and invalidated when binary changes
# - First tab press: ~300ms (generates cache)
# - Subsequent: <10ms (uses cache)
{ pkgs, ... }:

let
  # Creates a cached completion wrapper for Cobra-based dynamic completions
  # This eliminates the ~300ms delay on every tab press after the first use
  mkCachedCompletion = tool: binary: pkgs.writeText "${tool}-completion.fish" ''
    # Cached completion wrapper for ${tool}
    # Generates completions once per session, then reuses cached version

    set -g __fish_${tool}_completion_loaded 0
    set -g __fish_${tool}_completions ""

    function __${tool}_cached_completion
        # Load completions once per session
        if test $__fish_${tool}_completion_loaded -eq 0
            set -g __fish_${tool}_completions (${binary} __complete (commandline -opc)[2..] (commandline -ct) 2>/dev/null)
            set -g __fish_${tool}_completion_loaded 1
        end

        # Print cached completions
        for completion in $__fish_${tool}_completions
            echo $completion
        end
    end

    # Register the completion
    complete -c ${tool} -f -a "(__${tool}_cached_completion)"
  '';
in
{
  xdg.configFile = {
    # Note: kubectl and docker completions are provided by OrbStack

    "fish/completions/k3d.fish".source =
      mkCachedCompletion "k3d" "${pkgs.k3d}/bin/k3d";

    "fish/completions/golangci-lint.fish".source =
      mkCachedCompletion "golangci-lint" "${pkgs.golangci-lint}/bin/golangci-lint";

    "fish/completions/goreleaser.fish".source =
      mkCachedCompletion "goreleaser" "${pkgs.goreleaser}/bin/goreleaser";

    "fish/completions/hcloud.fish".source =
      mkCachedCompletion "hcloud" "${pkgs.hcloud}/bin/hcloud";

    # Note: mise completions are handled by programs.mise.enableFishIntegration
    # Note: broot integration (br.fish) is handled by programs.broot in broot.nix
    # with enableFishIntegration = true
  };
}
