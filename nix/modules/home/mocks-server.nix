{
  config,
  lib,
  pkgs,
  ...
}: let
  port = "8140";
  root = "${config.home.homeDirectory}/Projects/github.com/smykla-skalski/smyklot/.bart/mocks";
in {
  launchd.agents.mocks-server = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "-m"
        "http.server"
        "--bind"
        "127.0.0.1"
        "--directory"
        root
        port
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/mocks-server.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/mocks-server.error.log";
    };
  };
}
