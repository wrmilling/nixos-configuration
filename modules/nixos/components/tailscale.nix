{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = lib.mkEnableOption "tailscale packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      package = pkgs.tailscale;
    };
  };
}