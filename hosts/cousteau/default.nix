# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  modules = {
    system.base.enable = true;
    k8sUtils.enable = true;
  };

  wsl.enable = true;
  wsl.defaultUser = "w4cbe";
  wsl.wslConf.network.hostname = "cousteau";
  wsl.usbip = {
    enable = true;
    autoAttach = [
      "8-1"
    ];
  };

  environment.systemPackages = [
    pkgs.yubikey-manager
    pkgs.libfido2
  ];

  services.pcscd.enable = true;
  services.udev = {
    enable = true;
    packages = [ pkgs.yubikey-personalization ];
    extraRules = ''
      SUBSYSTEM=="usb", MODE="0666"
      KERNEL=="hidraw*", SUBSYSTEM=="hidraw", TAG+="uaccess", MODE="0666"
    '';
  };

  # Allow VSCode to work from windows
  programs.nix-ld.enable = true;

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      w4cbe = import ../../home-manager/server;
    };
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  system.stateVersion = "24.11";
}
