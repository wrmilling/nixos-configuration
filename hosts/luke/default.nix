{
  config,
  inputs,
  outputs,
  pkgs,
  lib,
  secrets,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./openvz.nix
    ../common/server.nix
    ../common/optional/webhost.nix
  ];

  networking = {
    hostName = "luke";
    domain = secrets.hosts.luke.domain;
    useNetworkd = true;
    nameservers = ["8.8.8.8" "8.8.4.4"];
  };

  # Disable resolved for now, issue on OpenVZ
  services.resolved = {
    enable = false;
    dnssec = "false";
  };

  # Manually set resolv.conf for now
  environment.etc = {
    "resolv.conf".text = "nameserver 8.8.8.8\n";
  };

  systemd.network.networks.venet0 = {
    name = "venet0";
    addresses = [
      {
        addressConfig = {
          Address = "127.0.0.1/32";
          Scope = "host";
        };
      }
      {
        addressConfig = {
          Address = "${secrets.hosts.luke.address}/32";
          Broadcast = "${secrets.hosts.luke.address}";
          Scope = "global";
        };
      }
    ];
    networkConfig = {
      DHCP = "no";
      DNSSEC = "no";
      DefaultRouteOnDevice = "yes";
      ConfigureWithoutCarrier = "yes";
    };
  };

  # While I Debug
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AItff1gZXXS0qVsAIy8qBz4e/1etAArnj+qccuUVwf8ybAYQwD4910h1D4rFBSjf9KmMdY1nesprNKM8ICeA5jSH7kblkRYOB3nUjg5B/GqWDgtjU4ooJBBP7ibuqZfbwDzTPH1Cuodc4CBPdy/yulCHpAZRU7YauXxXvQOckbd8uHoPC5wggQSjVszsyfaQGTx0N0hMv1aHBPstp9It9JiHuxtwSvyctRiXFdWdmsBbTla086Nuc8uFoaKWiuxIRyplW0qSswIbrBdVUY7q+ss38pjcDhHSag3tItEU9FRBfYkcT3PxsmHFYTgjX4bNl2Y1VcxQ0n3Fs5yZYWZcbDtooPrHSyMwaoqm+QECIu6nKSVsa/Iq0d/3JaA8MJZ/zV1JlydSMcfi2XcXYvJauyuQgwOVIyXhb6N/zTs4pgwlVMkxtUCatPe2zWHvfRBOtfNbw1zDW/pzh/lJcIPuWmESv/zPcsJC4r+cD0lASi+UjZyIeVOaKuhznO7kRPfRO4H8BwW4T2qSo5xDrjR7gR820TyJWEUZbMdMByrgZvWyJEoxPfrAhMQdtnbaX0nRvdYcori/cL1b8QxUZTLdZgwVaxeyh0/P5fOK01OO9MH7O19ZtkkAx9dswk1Y5rQWzmQp6Ab+pAizPNZBwNDxdQaoB48ZAX/KDG3jmSdZgw=="
  ];
  services.openssh.settings.PermitRootLogin = lib.mkForce "prohibit-password";
  users.users.w4cbe.passwordFile = lib.mkForce null;
  nix.settings.trusted-users = ["root" "@wheel"];

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.11";
}
