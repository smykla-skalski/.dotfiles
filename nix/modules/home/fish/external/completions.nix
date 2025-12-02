# Tool completions and additional configurations
{ ... }:

{
  xdg.configFile = {
    # docker conf.d
    "fish/conf.d/docker.fish".source = ../../../../dotfiles/fish/conf.d/docker.fish;

    # completions from tools
    "fish/completions/docker.fish".source = ../../../../dotfiles/fish/completions/docker.fish;
    "fish/completions/golangci-lint.fish".source = ../../../../dotfiles/fish/completions/golangci-lint.fish;
    "fish/completions/goreleaser.fish".source = ../../../../dotfiles/fish/completions/goreleaser.fish;
    "fish/completions/hcloud.fish".source = ../../../../dotfiles/fish/completions/hcloud.fish;
    "fish/completions/k3d.fish".source = ../../../../dotfiles/fish/completions/k3d.fish;
    "fish/completions/kubectl.fish".source = ../../../../dotfiles/fish/completions/kubectl.fish;
    "fish/completions/mise.fish".source = ../../../../dotfiles/fish/completions/mise.fish;

    # Note: broot integration (br.fish) is handled by programs.broot in broot.nix
    # with enableFishIntegration = true
  };
}
