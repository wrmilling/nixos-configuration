{
  config,
  lib,
  pkgs,
  ...
}:
let
  tailscale-package = pkgs.tailscale;
in
{
  environment.systemPackages = [ ];

  services.tailscale = {
    enable = true;
    package = tailscale-package;
  };
}
