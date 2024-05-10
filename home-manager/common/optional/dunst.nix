{
  pkgs,
  lib,
  config,
  ...
}:
{
  services.dunst = {
    enable = true;
  };
}
