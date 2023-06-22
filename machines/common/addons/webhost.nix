{ config, lib, pkgs, ... }:

let 
  domain = config.networking.domain;
in {
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  services.nginx.enable = true;
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "Winston@${domain}";
  services.nginx.virtualHosts."${domain}" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/${domain}";
  };
}
