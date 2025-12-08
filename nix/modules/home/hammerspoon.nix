{ config, lib, ... }:

{
  # Deploy Hammerspoon configuration and scripts
  home.file = {
    ".hammerspoon/init.lua".source = ./hammerspoon/init.lua;
    ".hammerspoon/change-jetbrains-fonts.groovy".source = ./hammerspoon/change-jetbrains-fonts.groovy;
    ".hammerspoon/lua".source = ./hammerspoon/lua;
  };
}
