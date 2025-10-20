{
  config,
  lib,
  pkgs,
  ...
}:
let
  hostname = config.networking.hostName;
  domain = config.networking.domain;
in
{
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
}
