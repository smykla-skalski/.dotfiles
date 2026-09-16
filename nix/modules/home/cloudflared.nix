{
  config,
  lib,
  pkgs,
  ...
}: let
  tunnelId = "4e33ff52-9bcd-44a8-86d2-0ad977d4b5d9";
  cloudflaredConfig = pkgs.writeText "cloudflared-my-smykla.yml" ''
    tunnel: ${tunnelId}
    credentials-file: ${config.home.homeDirectory}/.cloudflared/${tunnelId}.json

    ingress:
      - hostname: orca.smykla.com
        service: http://127.0.0.1:6768
      - hostname: pair.smykla.com
        service: http://127.0.0.1:55915
      - hostname: mocks.smykla.com
        service: http://127.0.0.1:8140
      # Vite binds the IPv6 loopback only ([::1]:5173), so 127.0.0.1 is refused and every
      # request returns 502 with "connection refused" in the tunnel log.
      - hostname: benchee.smykla.com
        service: http://[::1]:5173
      - service: http_status:404
  '';
in {
  xdg.configFile."cloudflared/config.yml".source = cloudflaredConfig;

  launchd.agents.cloudflared-my-smykla = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      ProgramArguments = [
        "/opt/homebrew/opt/cloudflared/bin/cloudflared"
        "tunnel"
        "--config"
        "${config.xdg.configHome}/cloudflared/config.yml"
        "run"
        "my-smykla"
      ];
      RunAtLoad = true;
      KeepAlive = true;
      ProcessType = "Background";
      ThrottleInterval = 10;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/cloudflared-my-smykla.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/cloudflared-my-smykla.error.log";
    };
  };
}
