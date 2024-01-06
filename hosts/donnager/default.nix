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
    inputs.hardware.nixosModules.lenovo-legion-y530-15ich
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
    ../common/laptop.nix
    ../common/optional/development.nix
    ../common/optional/docker.nix
    ../common/optional/gaming.nix
    ../common/optional/k8s-utils.nix
    ../common/optional/nixbuild-client.nix
    ../common/optional/printing.nix
    ../common/optional/tailscale.nix
    ../common/optional/virtualization.nix
    ../common/optional/zram.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Visual boot
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.kernelParams = ["quiet"];

  networking = {
    hostName = "donnager";
    domain = secrets.hosts.donnager.domain;
  };

  home-manager = {
    extraSpecialArgs = {inherit inputs outputs;};
    users = {
      w4cbe = import ../../home-manager/donnager;
    };
  };

  system.stateVersion = "23.11";
}
