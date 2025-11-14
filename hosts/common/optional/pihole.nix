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
    useDnsmasqConfig = true;
    lists = [
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts";
        description = "Steven Black's Unified Adlist";
      }
      {
        url = "https://raw.githubusercontent.com/hagezi/dns-blocklists/main/adblock/pro.txt";
        description = "HaGeZi's Pro DNS Blocklist";
      }
      {
        url = "https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/porn-only/hosts";
        description = "Steven Black's Why Wont You Think of the Children List";
      }
    ];
  };

  services.dnsmasq.settings = {
    conf-file = config.sops.secrets."pihole/customHosts".path;
  };

  services.pihole-web = {
    enable = true;
    ports = [ "5353s" ];
  };

  # config.sops.secrets."k3s/agent/nodeTokenFull".path;

}
