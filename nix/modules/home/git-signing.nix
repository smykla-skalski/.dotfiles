{
  config,
  lib,
  pkgs,
  ...
}: let
  home = config.home.homeDirectory;
  key = "${home}/.ssh/git_commit_signing_ed25519";
in {
  programs.git = {
    enable = true;
    signing.format = "ssh";
    settings = {
      user.name = "Bart Smykla";
      user.email = "bartek@smykla.com";
      user.signingkey = "${key}.pub";
      gpg.ssh.program = "${home}/.local/bin/agent-ssh-sign";
      gpg.ssh.allowedSignersFile = "${home}/.ssh/allowed_signers";
      commit.gpgsign = true;
    };
  };

  home.file.".local/bin/agent-ssh-sign" = {
    source = ../../../helper_scripts/agent-ssh-sign.sh;
    executable = true;
    force = true;
  };

  home.file.".local/bin/load-git-signing-key" = {
    source = ../../../helper_scripts/load-git-signing-key.sh;
    executable = true;
    force = true;
  };

  launchd.agents.git-commit-signing = lib.mkIf pkgs.stdenv.hostPlatform.isDarwin {
    enable = true;
    config = {
      ProgramArguments = ["${home}/.local/bin/load-git-signing-key"];
      RunAtLoad = true;
      LimitLoadToSessionType = "Aqua";
    };
  };
}
