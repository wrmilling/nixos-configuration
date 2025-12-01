{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "ehci_pci"
    "xhci_pci"
    "usb_storage"
    "usbhid"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" "zenpower" ]; # Added zenpower
  boot.extraModulePackages = [ config.boot.kernelPackages.zenpower ]; # Added zenpower
  boot.blacklistedKernelModules = [ "k10temp" ]; # Added zenpower

  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/2b28d733-0bfe-49f0-85db-ac47a8fd0786";
    crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/C57E-4E42";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}

