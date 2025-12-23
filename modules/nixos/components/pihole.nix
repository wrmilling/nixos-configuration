{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.pihole;
in
{
  options.modules.nixos.pihole = {
    enable = lib.mkEnableOption "piHole packages / settings";
    additionalHosts = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "File path to the additional hosts config";
    };
    customAddresses = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "File path to the custom addresses config";
    };
    customCnames = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "File path to the custom cname config";
    };
  };

  config = lib.mkIf cfg.enable {
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
          "addn-hosts=\"${config.modules.nixos.pihole.additionalHosts}\""
          "conf-file=\"${config.modules.nixos.pihole.customAddresses}\""
          "conf-file=\"${config.modules.nixos.pihole.customCnames}\""
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
      settings = {
        appdata_dir = "/var/cache/stubby";
        dns_transport_list = [
          "GETDNS_TRANSPORT_TLS"
        ];
        edns_client_subnet_private = 1;
        idle_timeout = 10000;
        listen_addresses = [
          "127.0.0.1@5353"
        ];
        log_level = "GETDNS_LOG_NOTICE";
        resolution_type = "GETDNS_RESOLUTION_STUB";
        round_robin_upstreams = 1;
        tls_authentication = "GETDNS_AUTHENTICATION_REQUIRED";
        tls_query_padding_blocksize = 128;
        upstream_recursive_servers = [
          {
            address_data = "1.1.1.1";
            tls_auth_name = "cloudflare-dns.com";
            # tls_pubkey_pinset = [{
            #   digest = "sha256";
            #   value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
            # }];
          }
          {
            address_data = "1.0.0.1";
            tls_auth_name = "cloudflare-dns.com";
            # tls_pubkey_pinset = [{
            #   digest = "sha256";
            #   value = "GP8Knf7qBae+aIfythytMbYnL+yowaWVeD6MoLHkVRg=";
            # }];
          }
        ];
      };
    };
  };
}