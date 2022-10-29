{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "nvme" "usbhid" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ ];
  boot.extraModulePackages = [ ];
  boot.kernelPatches = [
    {
      # Undervolt and Overclock for Pinebook Pro RK3399
      name = "pbp-undervolt-overclock";
      patch = ./patches/0001-RK3399-Undervolt-and-Overclock-dtb-for-Pinebook-Pro.patch;
    }
    {
      name = "pbp-fix-usb-pd-charging";
      patch = ./patches/0167-arm64-dts-rk3399-pinebook-pro-Fix-USB-PD-charging.patch;
    }
    {
      name = "pbp-improve-usb-c-support";
      patch = ./patches/0168-arm64-dts-rk3399-pinebook-pro-Improve-Type-C-support.patch;
    }
    {
      name = "pbp-remove-redundant-pinctrl";
      patch = ./patches/0169-arm64-dts-rk3399-pinebook-pro-Remove-redundant-pinct.patch;
    }
    {
      name = "pbp-remove-disused-features";
      patch = ./patches/0170-arm64-dts-rk3399-pinebook-pro-Remove-unused-features.patch;
    }
    {
      name = "pbp-disallow-usb2-phy-update-role";
      patch = ./patches/0171-arm64-dts-rk3399-pinebook-pro-Don-t-allow-usb2-phy-d.patch;
    }
    {
      name = "pbp-support-usbc-superposition";
      patch = ./patches/0172-arm64-dts-rockchip-rk3399-pinebook-pro-Support-both-.patch;
    }
    {
      name = "pbp-fix-audio-codec-freq";
      patch = ./patches/0438-arm64-dts-rk3399-pinebook-pro-Fix-codec-frequency-af.patch;
    }
    {
      name = "pbp-fix-audio-clk-I2S1-I2S2";
      patch = ./patches/0439-clk-rockchip-rk3399-Fix-audio-clock-setting-on-I2S1-.patch;
    }
    {
      name = "pbp-fix-audio-clk-better";
      patch = ./patches/0440-arm64-dts-rk3399-pinebook-pro-Fix-codec-frequency-af.patch;
    }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/34035012-4604-43ed-8df5-0a0294857c5e";
    fsType = "ext4";
  };

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/12A6-CC3E";
    fsType = "vfat";
  };

  fileSystems."/mnt/NVMe" = {
    device = "/dev/disk/by-uuid/a74ab374-fc3a-4f76-9505-36803c533acb";
    fsType = "ext4";
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
  powerManagement.cpuFreqGovernor = lib.mkDefault "ondemand";
}
