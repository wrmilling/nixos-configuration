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
  boot.kernelModules = [
    "kvm-amd"
    "zenpower"
  ]; # Added zenpower
  boot.extraModulePackages = [ config.boot.kernelPackages.zenpower ]; # Added zenpower
  boot.blacklistedKernelModules = [ "k10temp" ]; # Added zenpower

  # Fingerprint Reader
  services.fprintd.enable = true;
  services.fprintd.tod.enable = true;
  services.fprintd.tod.driver = pkgs.libfprint-2-tod1-goodix;

  # Boot greeter uses the "login" PAM service; fprintd there blocks password
  # login for its full timeout when the sensor isn't touched. Screen unlock
  # still gets fingerprint via the separate kde/kde-fingerprint services.
  security.pam.services.login.fprintAuth = false;

  # Goodix reader (06cb:00df) drops off the bus under USB autosuspend, breaking lock-screen unlock.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="06cb", ATTR{idProduct}=="00df", TEST=="power/control", ATTR{power/control}="on"
  '';

  # filesystem.nix enables rpcbind for NFS hosts; icarus has no NFS mounts and doesn't need it exposed.
  services.rpcbind.enable = lib.mkForce false;

  fileSystems."/" = {
    device = "/dev/mapper/cryptroot";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/49badd4e-2c54-4ec0-a4f4-893e664df466";
    crypttabExtraOpts = [
      "tpm2-device=auto"
      "tpm2-measure-pcr=yes"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/B107-307C";
    fsType = "vfat";
    options = [
      "fmask=0022"
      "dmask=0022"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
