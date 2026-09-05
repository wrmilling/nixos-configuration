{
  inputs,
  pkgs,
  secrets,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.desktop.enable = true;
    nixos.appimage.enable = true;
    nixos.agentSandbox = {
      enable = true;
      extraShares = [
        {
          # Matches the path modules/home/personal.nix's activation script copies to.
          source = "/home/w4cbe/.config/agent-sandbox/kube";
          mountPoint = "/home/w4cbe/.kube";
          tag = "kube";
          readOnly = true;
        }
      ];
    };
    nixos.development.enable = true;
    nixos.dockerRootless.enable = true;
    nixos.gaming.enable = true;
    nixos.starCitizen.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.nvidia.enable = true;
    # nixos.ollama.enable = true;
    # nixos.ollama.acceleration = "cuda";
    nixos.printing.enable = true;
    nixos.secureboot.enable = true;
    nixos.smartcard.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.visualBoot.enable = true;
    nixos.onedrive.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Since secureboot is enabled on this host and we have Windows on another drive, try to enable rebooting to windows:
  boot.lanzaboote.settings.reboot-for-bitlocker = true;

  # services.displayManager.sddm.wayland.enable = lib.mkForce false;

  networking = {
    hostName = "enterprise";
    domain = secrets.hosts.common.domain;
    # Though a desktop, has wifi for now, using networkmanager to manage.
    networkmanager.enable = true;
  };

  system.stateVersion = "24.11";
}
