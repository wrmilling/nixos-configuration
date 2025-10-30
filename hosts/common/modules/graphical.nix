{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.mesa
    pkgs.mesa-demos
  ];
}
