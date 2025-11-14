{
  config,
  lib,
  pkgs,
  ...
}:
{

  sops.secrets."pihole/customHosts" = {
    owner = "pihole";
    sopsFile = ../../../secrets/pihole.yaml;
  };

  services.pihole-ftl = {
    enable = true;
    openFirewallDNS = true;
    openFirewallWebserver = true;
    user = "pihole";
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
    settings = {
      misc.dnsmasq_lines = [
        "conf-file=\"${config.sops.secrets."pihole/customHosts".path}\""
        "except-interface=nonexisting"
      ];
      dns.upstreams = [
        "127.0.0.1#5353"
      ];
    };
  };

  services.pihole-web = {
    enable = true;
    ports = [ "8443s" ];
  };

  services.stubby = {
    enable = true;
    settings = pkgs.stubby.passthru.settingsExample // {
      listen_address = "127.0.0.1@5353";
      upstream_recursive_servers = [
        {
          address_data = "1.1.1.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        }
        {
          address_data = "1.0.0.1";
          tls_auth_name = "cloudflare-dns.com";
          tls_pubkey_pinset = [{
            digest = "sha256";
            value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
          }];
        }
      ];
    };
  };

}
