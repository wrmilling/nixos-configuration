{ config, inputs, outputs, pkgs, lib, secrets, ... }:

{
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
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

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  system.stateVersion = "23.05";
}

