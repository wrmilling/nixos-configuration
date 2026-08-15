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

    # Cancel the upstream module's After=NetworkManager-wait-online.service,
    # which otherwise stalls the login greeter ~5s waiting on it.
    systemd.services.tailscaled.after = lib.mkForce [ ];
  };
}
