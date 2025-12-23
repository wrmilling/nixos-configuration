{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.tailscale;
in
{
  options.modules.nixos.tailscale = {
    enable = lib.mkEnableOption "tailscale packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
    };
  };
}