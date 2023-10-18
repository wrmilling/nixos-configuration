{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [ (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  hardware.opengl.driSupport32Bit = true;

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/b0fdc274-87f9-45e1-b670-ffa940554969";
      fsType = "ext4";
    };

  boot.initrd.luks.devices."cryptroot".device = "/dev/disk/by-uuid/8c22fb74-e2c6-405d-bce1-3b5d424bcdce";

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/47E5-D29E";
      fsType = "vfat";
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
