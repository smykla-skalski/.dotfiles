# Fish shell plugins and plugin-specific configurations
{ pkgs, ... }:

{
  programs.fish.plugins = [
    {
      name = "fish-history-merge";
      src = pkgs.fetchFromGitHub {
        owner = "2m";
        repo = "fish-history-merge";
        rev = "7e415b8ab843a64313708273cf659efbf471ad39";
        sha256 = "1hlc2ghnc8xidwzj2v1rjrw7gbpkkkld9y2mg4dh2qmcvlizcbd3";
      };
    }
    {
      name = "fzf-fish";
      src = pkgs.fishPlugins.fzf-fish.src;
    }
  ];
}
