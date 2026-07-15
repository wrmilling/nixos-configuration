{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}:
let
  filebrowserTlsDir = "/var/lib/filebrowser-tls";
  filebrowserTlsCert = "${filebrowserTlsDir}/cert.pem";
  filebrowserTlsKey = "${filebrowserTlsDir}/key.pem";
  updateFilebrowserTlsCertificate = pkgs.writeShellScript "update-filebrowser-tls-certificate" ''
    set -euo pipefail

    export PATH=${lib.makeBinPath [
      config.services.tailscale.package
      pkgs.coreutils
      pkgs.jq
      pkgs.systemd
    ]}

    install -d -m 0750 -o root -g nginx ${filebrowserTlsDir}

    dns_name=""
    for _ in $(seq 1 30); do
      dns_name="$(tailscale status --json | jq -r '.Self.DNSName // empty')"
      dns_name="''${dns_name%.}"

      if [ -n "$dns_name" ]; then
        break
      fi

      sleep 2
    done

    if [ -z "$dns_name" ]; then
      echo "Unable to determine Tailscale DNS name" >&2
      exit 1
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    tailscale cert \
      --cert-file "$tmpdir/cert.pem" \
      --key-file "$tmpdir/key.pem" \
      "$dns_name"

    install -m 0640 -o root -g nginx "$tmpdir/cert.pem" ${filebrowserTlsCert}
    install -m 0640 -o root -g nginx "$tmpdir/key.pem" ${filebrowserTlsKey}

    if systemctl is-active --quiet nginx.service; then
      systemctl reload --no-block nginx.service
    fi
  '';
in
{
  imports = [
    inputs.hardware.nixosModules.raspberry-pi-4
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  sops.secrets."nixbuild/client-ssh-key" = {
    owner = "root";
    mode = "0400";
    sopsFile = ../../../secrets/nixbuild-arm.yaml;
  };

  sops.secrets."tailscale/psk" = {
    owner = "root";
    sopsFile = ../../../secrets/owen.yaml;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  modules = {
    machineType.server.enable = true;
    nixos.sshd.banner = "${secrets.sshd.banner}";
    nixos.nixbuild-client = {
      enable = true;
      sshKeyPath = config.sops.secrets."nixbuild/client-ssh-key".path;
    };
    nixos.rpi-poe-hat.enable = true;
    nixos.tailscale.enable = true;
  };

  services.openssh.openFirewall = false;

  services.tailscale = {
    authKeyFile = config.sops.secrets."tailscale/psk".path;
    openFirewall = true;
    permitCertUid = "nginx";
  };

  services.filebrowser = {
    enable = true;
    settings = {
      address = "127.0.0.1";
      port = 8080;
      root = "/mnt/media/Society";
      database = "/var/lib/filebrowser/database.db";
      followExternalSymlinks = true;
    };
  };

  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."_" = {
      default = true;
      onlySSL = true;
      sslCertificate = filebrowserTlsCert;
      sslCertificateKey = filebrowserTlsKey;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${toString config.services.filebrowser.settings.port}";
        proxyWebsockets = true;
      };
    };
  };

  networking.firewall.interfaces = {
    end0.allowedTCPPorts = [
      22
      443
    ];
    tailscale0.allowedTCPPorts = [ 443 ];
  };

  systemd.services.filebrowser-tailscale-cert = {
    description = "Provision Tailscale TLS certificate for File Browser";
    wants = [
      "network-online.target"
      "tailscaled.service"
      "tailscaled-autoconnect.service"
    ];
    after = [
      "network-online.target"
      "tailscaled.service"
      "tailscaled-autoconnect.service"
    ];
    before = [ "nginx.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = updateFilebrowserTlsCertificate;
    };
  };

  systemd.services.nginx = {
    requires = [ "filebrowser-tailscale-cert.service" ];
    after = [ "filebrowser-tailscale-cert.service" ];
  };

  systemd.services.filebrowser = {
    serviceConfig = {
      Restart = "always";
      RestartSec = "5s";
    };
  };

  systemd.timers.filebrowser-tailscale-cert = {
    description = "Renew Tailscale TLS certificate for File Browser";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "30m";
      OnUnitActiveSec = "12h";
      RandomizedDelaySec = "30m";
      Unit = "filebrowser-tailscale-cert.service";
    };
  };

  # Artifact of the nixos user being created by default on the rpi images
  users.users.w4cbe.uid = lib.mkForce 1001;

  boot.kernelParams = [
    "cgroup_memory=1"
    "cgroup_enable=memory"
  ];

  networking = {
    hostName = "owen";
    domain = secrets.hosts.common-homelab.domain;
    useDHCP = lib.mkDefault true;
    interfaces = {
      end0.ipv4.addresses = [
        {
          address = secrets.hosts.owen.address;
          prefixLength = 24;
        }
      ];
    };
    defaultGateway = secrets.hosts.common-homelab.defaultGateway;
    nameservers = secrets.hosts.common-homelab.nameservers;
  };

  system.stateVersion = "25.05";
}
