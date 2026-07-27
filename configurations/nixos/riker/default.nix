{
  config,
  inputs,
  outputs,
  secrets,
  lib,
  pkgs,
  ...
}:
let
  # riker's CPU/GPU operating-point overclock/undervolt curve. Patches the
  # *current* kernel's own stock dtb on every build, so it tracks kernel
  # updates instead of freezing a fixed dtb blob.
  overclockedDtb = pkgs.runCommand "rk3399-pinebook-pro-overclocked.dtb" {
    nativeBuildInputs = [
      pkgs.dtc
      pkgs.python3
    ];
  } ''
    dtc -I dtb -O dts -o base.dts ${config.boot.kernelPackages.kernel}/dtbs/rockchip/rk3399-pinebook-pro.dtb
    python3 ${./dtb-overclock/patch-opp-tables.py} base.dts patched.dts
    dtc -I dts -O dtb -o $out patched.dts
  '';
in
{
  imports = [
    inputs.hardware.nixosModules.pine64-pinebook-pro
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.amateurRadio.enable = true;
    nixos.development.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.tailscale.enable = true;
    #nixos.virtualization.enable = true;
    nixos.sway.enable = true;
    nixos.visualBoot.enable = true;
    nixos.zram.enable = true;
  };

  networking = {
    hostName = "riker";
    domain = secrets.hosts.common.domain;
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = false;
  boot.kernelParams = lib.mkAfter [ "console=tty0" ];

  # The EDK2/TianoCore UEFI firmware on this Pinebook Pro loads the device
  # tree from a fixed firmware-level path rather than a per-generation
  # devicetree= entry, so nothing normally keeps it in sync with the active
  # kernel. Refresh it from the current generation's own kernel package on
  # every bootloader install.
  boot.loader.systemd-boot.extraInstallCommands = ''
    mkdir -p /boot/dtb/rockchip
    cp ${overclockedDtb} /boot/dtb/rockchip/rk3399-pinebook-pro.dtb
  '';

  boot.initrd.luks.devices = {
    cryptroot = {
      device = "/dev/disk/by-uuid/ddce2ffe-beb7-4e54-a2ff-f0759d15d55d";
      allowDiscards = true;
      preLVM = true;
    };
  };

  environment.etc = {
    crypttab = {
      text = ''
        nvmecrypt /dev/disk/by-uuid/92cf1e12-72a6-48fd-911f-5249183e5c64 /home/luks/nvme.key luks
      '';
      mode = "0440";
    };
  };

  system.stateVersion = "24.11";
}
