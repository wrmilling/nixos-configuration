{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/34035012-4604-43ed-8df5-0a0294857c5e";
    fsType = "ext4";
  };

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/12A6-CC3E";
    fsType = "vfat";
  };

  fileSystems."/mnt/NVMe" = {
    device = "/dev/disk/by-uuid/a74ab374-fc3a-4f76-9505-36803c533acb"
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
