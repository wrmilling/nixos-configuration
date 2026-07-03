{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.kernelParams = [ "amd_pstate=active" ];
  boot.extraModulePackages = [ ];

  hardware.enableAllFirmware = true;
  hardware.enableRedistributableFirmware = true;

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/ae2f391b-4a1b-4e12-a128-702aa725ac7b";
    crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/BA1E-5D9F";
    fsType = "vfat";
  };

  environment.etc.crypttab.text = ''
    helium /dev/disk/by-uuid/760e3749-cd08-4941-a8f4-babc075ba66c /root/storage-drives.key luks
    fire /dev/disk/by-uuid/77007c73-eaf4-4b53-8622-9ced3767cc32 /root/storage-drives.key luks
  '';

  fileSystems."/mnt/helium" = {
    device = "/dev/mapper/helium";
    fsType = "ext4";
  };

  fileSystems."/mnt/fire" = {
    device = "/dev/mapper/fire";
    fsType = "ext4";
  };

  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 32 * 1024;
    }
  ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
