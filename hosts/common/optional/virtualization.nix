{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.qemu
    pkgs.qemu-utils
  ];
}
