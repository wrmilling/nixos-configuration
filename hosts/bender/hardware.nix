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
    "xhci_pci"
    "ahci"
    "nvme"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-intel"
    "wl"
  ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.kernelParams = [
    "acpi_osi=Darwin"
    "acpi_mask_gpe=0x06"
  ];

  hardware.graphics.enable32Bit = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/48895c21-5ccc-4a82-886b-a5f366555790";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/eeaef019-5683-4caa-b10c-5b9e87584c03";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/CC6B-4D3E";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
