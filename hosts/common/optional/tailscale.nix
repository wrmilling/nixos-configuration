{
  config,
  lib,
  pkgs,
  ...
}: let
  tailscale-package = pkgs.unstable.tailscale;
in {
  environment.systemPackages = with pkgs; [
    barrier
  ];

  services.tailscale = {
    enable = true;
    package = tailscale-package;
  };
}
