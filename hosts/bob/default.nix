{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      ./openvz.nix
      ../common/server.nix
    ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  networking = {
    hostName = "bob";
    useNetworkd = true;
    nameservers = [ "8.8.8.8" "8.8.4.4" ];
  };

  services.resolved = {
    dnssec = "false";
  };

  systemd.network.networks.venet0 = {
    name = "venet0";
    addresses = [
      { addressConfig = {
          Address = "127.0.0.1/32";
          Scope = "host";
        };
      }
      {
        addressConfig = {
          Address = "${secrets.hosts.bob.ipAddress}/32";
          Broadcast = "${secrets.hosts.bob.ipAddress}";
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

  services.openssh.enable = true;

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC7AItff1gZXXS0qVsAIy8qBz4e/1etAArnj+qccuUVwf8ybAYQwD4910h1D4rFBSjf9KmMdY1nesprNKM8ICeA5jSH7kblkRYOB3nUjg5B/GqWDgtjU4ooJBBP7ibuqZfbwDzTPH1Cuodc4CBPdy/yulCHpAZRU7YauXxXvQOckbd8uHoPC5wggQSjVszsyfaQGTx0N0hMv1aHBPstp9It9JiHuxtwSvyctRiXFdWdmsBbTla086Nuc8uFoaKWiuxIRyplW0qSswIbrBdVUY7q+ss38pjcDhHSag3tItEU9FRBfYkcT3PxsmHFYTgjX4bNl2Y1VcxQ0n3Fs5yZYWZcbDtooPrHSyMwaoqm+QECIu6nKSVsa/Iq0d/3JaA8MJZ/zV1JlydSMcfi2XcXYvJauyuQgwOVIyXhb6N/zTs4pgwlVMkxtUCatPe2zWHvfRBOtfNbw1zDW/pzh/lJcIPuWmESv/zPcsJC4r+cD0lASi+UjZyIeVOaKuhznO7kRPfRO4H8BwW4T2qSo5xDrjR7gR820TyJWEUZbMdMByrgZvWyJEoxPfrAhMQdtnbaX0nRvdYcori/cL1b8QxUZTLdZgwVaxeyh0/P5fOK01OO9MH7O19ZtkkAx9dswk1Y5rQWzmQp6Ab+pAizPNZBwNDxdQaoB48ZAX/KDG3jmSdZgw=="
  ];

  system.stateVersion = "23.05";
}

