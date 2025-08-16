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
    "xhci_pci"
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  # Fingerprint Reader
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d1691757-13d4-437f-98d0-6ba92a7e892f";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/7d2c1c69-e930-4819-bc32-2f1d482b1412";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/DA96-A70D";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}