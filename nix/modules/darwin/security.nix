{ pkgs, lib, ... }:

{
  # Touch ID for sudo (works in tmux with pam-reattach)
  security.pam.services.sudo_local.touchIdAuth = true;
  security.pam.services.sudo_local.reattach = true;
}
