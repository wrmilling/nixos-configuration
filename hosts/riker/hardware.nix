{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

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

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/ec322269-b22e-4022-8aa9-74008c8411a3";
      fsType = "ext4";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/7092-A9AA";
      fsType = "vfat";
    };

  # fileSystems."/mnt/NVMe" = {
  #   device = "/dev/disk/by-uuid/a74ab374-fc3a-4f76-9505-36803c533acb";
  #   fsType = "ext4";
  # };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
