{ config, lib, pkgs, ... }:

let secrets = import ../secrets.nix; in

{
  networking.firewall.allowedTCPPorts = [ 80 443 ]
  services.nginx.enable = true;
  security.acme.acceptTerms = true;
  security.acme.defaults.email = "Winston@${secrets.DOMAIN}";
  services.nginx.virtualHosts."${secrets.DOMAIN}" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/${secrets.DOMAIN}";
  };
}
