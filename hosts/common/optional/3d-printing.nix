{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.prusa-slicer
  ];
}
