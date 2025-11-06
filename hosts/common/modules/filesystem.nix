{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.exfat
    pkgs.nfs-utils
  ];
}
