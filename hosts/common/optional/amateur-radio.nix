{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.chirp
    pkgs.svxlink
  ];
}
