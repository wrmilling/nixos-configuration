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
    "usb_storage"
    "sd_mod"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.graphics.enable32Bit = true;

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/d5bf9c7a-2d21-4d94-a0eb-ecc2dd276d64";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot".device =
    "/dev/disk/by-uuid/3645d7ff-fce0-4a89-816e-c24a1ed84d5f";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/1A3B-9F79";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  environment.etc = {
    crypttab = {
      text = ''
        firecudacrypt /dev/disk/by-uuid/a2bd6fb1-8a45-4da2-822f-ff07d818782f /home/luks/firecuda.key luks
      '';
      mode = "0440";
    };
  };

  fileSystems."/mnt/Media" = {
    device = "/dev/disk/by-uuid/2352844f-cb1f-49f8-9d09-aea0db2577d3";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
