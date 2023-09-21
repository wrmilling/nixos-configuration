{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.tailscale
    barrier
  ];

  services.tailscale.enable = true;
}
