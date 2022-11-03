{ config, lib, pkgs, ... }:

let secrets = import ../secrets.nix; in

{
  services.nginx.enable = true; 
  services.nginx.virtualHosts."${secrets.DOMAIN}" = {
    forceSSL = true;
    enableACME = true;
    root = "/var/www/${secrets.DOMAIN}";
  };
}
