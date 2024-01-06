{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = ["nvme" "usbhid"];
  boot.initrd.kernelModules = ["dm-snapshot"];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  # boot.kernelPatches = [
  #   {
  #     # Undervolt and Overclock for Pinebook Pro RK3399
  #     name = "pbp-undervolt-overclock";
  #     patch = ./patches/0001-RK3399-Undervolt-and-Overclock-dtb-for-Pinebook-Pro.patch;
  #   }
  #   {
  #     # All of https://github.com/megous/linux patches in one
  #     name = "megous-all";
  #     patch = ./patches/0002-megous-6.0.x-all.patch;
  #   }
  # ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/8cf3381e-ef78-480a-a6a4-b5dc3cf62af4";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/2B37-1659";
    fsType = "vfat";
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
