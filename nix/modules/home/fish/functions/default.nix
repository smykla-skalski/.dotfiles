# Fish shell functions index
# Imports all function modules
{ ... }:

{
  imports = [
    ./git.nix
    ./kubernetes.nix
    ./npm.nix
    ./python.nix
    ./utilities.nix
  ];
}
