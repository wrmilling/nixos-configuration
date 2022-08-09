{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    tailscale
    barrier
  ];
}
