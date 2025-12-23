{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.webhost;
  hostname = config.networking.hostName;
  domain = config.networking.domain;
in
{
  options.modules.nixos.webhost = {
    enable = lib.mkEnableOption "webhost packages / settings";
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedTCPPorts = [
      80
      443
    ];
    services.nginx.enable = true;
    security.acme.acceptTerms = true;
    security.acme.defaults.email = "admin@${domain}";
    services.nginx.virtualHosts."${hostname}.${domain}" = {
      forceSSL = true;
      enableACME = true;
      root = "/var/www/${hostname}.${domain}";
    };
  };
}