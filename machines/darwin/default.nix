# hosts/YourHostName/default.nix
{ pkgs, config, inputs, outputs, lib, secrets, ... }:
{
  imports = 
  [
    inputs.home-manager.nixosModules.home-manager
  ];

  # Make sure the nix daemon always runs
  services.nix-daemon.enable = true;
  # Installs a version of nix, that dosen't need "experimental-features = nix-command flakes" in /etc/nix/nix.conf
  services.nix-daemon.package = pkgs.nixFlakes;
  
  # if you use zsh (the default on new macOS installations),
  # you'll need to enable this so nix-darwin creates a zshrc sourcing needed environment changes
  programs.zsh.enable = true;
  # bash is enabled by default

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs secrets; };
    users = {
      "${secrets.machines.work-mac.username}" = import ../../home-manager/darwin;
    };
  };

}