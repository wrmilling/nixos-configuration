{
  inputs,
  pkgs,
  secrets,
  ...
}:
{
  imports = [
    inputs.hardware.nixosModules.hp-elitebook-845g8
    inputs.home-manager.nixosModules.home-manager
    ./hardware.nix
  ];

  modules = {
    machineType.laptop.enable = true;
    nixos.threeDPrinting.enable = true;
    nixos.amateurRadio.enable = true;
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
    nixos.flipper.enable = true;
    nixos.fusion360.enable = true;
    nixos.gaming.enable = true;
    nixos.vr.enable = true;
    nixos.k8sUtils.enable = true;
    nixos.nzbget.enable = true;
    # nixos.ollama.enable = true;
    nixos.printing.enable = true;
    nixos.secureboot.enable = true;
    nixos.smartcard.enable = true;
    nixos.tailscale.enable = true;
    nixos.virtualization.enable = true;
    nixos.visualBoot.enable = true;
    nixos.wireshark.enable = true;
    nixos.onedrive.enable = true;
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Enabled lanzaboote through secureboot.nix optional import.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking = {
    hostName = "icarus";
    domain = secrets.hosts.common.domain;
  };

  system.stateVersion = "25.05";
}
