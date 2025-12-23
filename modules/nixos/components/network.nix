{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.network;
in
{
  options.modules.nixos.network = {
    enable = lib.mkEnableOption "network packages / settings";
  };

  config = lib.mkIf cfg.enable {
    networking.useDHCP = lib.mkDefault true;
    # networking.interfaces.wlan0.useDHCP = lib.mkDefault true;

    # reverse filtering fix for wireguard / tailscale
    networking.firewall.checkReversePath = "loose";
  };
}