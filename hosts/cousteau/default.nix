# NixOS-WSL specific options are documented on the NixOS-WSL repository:
# https://github.com/nix-community/NixOS-WSL

{ config, lib, pkgs, inputs, outputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../common/default.nix
  ];

  wsl.enable = true;
  wsl.defaultUser = "w4cbe";
  wsl.wslConf.network.hostname = "cousteau";

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