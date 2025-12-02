{ config, lib, ... }:

{
  # Deploy Hammerspoon configuration from external Lua file
  home.file.".hammerspoon/init.lua".source = ./hammerspoon/init.lua;
}
