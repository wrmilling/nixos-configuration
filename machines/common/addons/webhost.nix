{ config, lib, pkgs, ... }:

let
  domain = builtins.readFile config.sops.secrets.domain.path;
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
