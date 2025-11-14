{
  config,
  lib,
  pkgs,
  ...
}:
{

  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
  };

  services.pihole-web = {
    enable = true;
    port = "5353s";
  };

}
