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
  environment.systemPackages = [ pkgs.barrier ];

  services.tailscale = {
    enable = true;
    package = tailscale-package;
  };
}
