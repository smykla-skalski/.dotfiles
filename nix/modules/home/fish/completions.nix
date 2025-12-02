# Tool completions and additional configurations
#
# Fish completions are generated at build time from CLI tools that support
# `<tool> completion fish` (Cobra-based tools) or similar completion commands.
#
# This approach:
# - Eliminates manual maintenance of completion files
# - Ensures completions stay synchronized with tool versions
# - Provides fast shell startup (no runtime generation overhead)
# - Regenerates automatically when tool versions change in nixpkgs
{ pkgs, ... }:

{
  xdg.configFile = {
    # Build-time generated completions
    # These tools all support `<tool> completion fish` via Cobra framework
    "fish/completions/kubectl.fish".source = pkgs.runCommand "kubectl-completion" {} ''
      ${pkgs.kubectl}/bin/kubectl completion fish > $out
    '';

    "fish/completions/docker.fish".source = pkgs.runCommand "docker-completion" {} ''
      ${pkgs.docker-client}/bin/docker completion fish > $out
    '';

    "fish/completions/k3d.fish".source = pkgs.runCommand "k3d-completion" {} ''
      ${pkgs.k3d}/bin/k3d completion fish > $out
    '';

    "fish/completions/golangci-lint.fish".source = pkgs.runCommand "golangci-lint-completion" {} ''
      ${pkgs.golangci-lint}/bin/golangci-lint completion fish > $out
    '';

    "fish/completions/goreleaser.fish".source = pkgs.runCommand "goreleaser-completion" {} ''
      ${pkgs.goreleaser}/bin/goreleaser completion fish > $out
    '';

    "fish/completions/hcloud.fish".source = pkgs.runCommand "hcloud-completion" {} ''
      ${pkgs.hcloud}/bin/hcloud completion fish > $out
    '';

    # Note: mise completions are handled by programs.mise.enableFishIntegration
    # Note: broot integration (br.fish) is handled by programs.broot in broot.nix
    # with enableFishIntegration = true
  };
}
