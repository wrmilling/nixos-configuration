# hosts/YourHostName/default.nix
{ pkgs, config, inputs, outputs, lib, secrets, ... }:
{
  imports = 
  [
    inputs.home-manager.darwinModules.home-manager
  ];
  
  services.nix-daemon.enable = true;
  nix.package = pkgs.nixVersions.nix_2_16;
  security.pki-certificateFiles = [ "/etc/ssl/thd_combined.pem" ];

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs secrets; };
    users.WRM6768 = import ../../home-manager/darwin;
  };
}