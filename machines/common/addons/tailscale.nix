{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tailscale
    barrier
  ];

  services.tailscale.enable = true;
}
