{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.plasma6;
in
{
  options.modules.nixos.plasma6 = {
    enable = lib.mkEnableOption "plasma6 packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6 = {
        enable = true;
      };
      displayManager.plasma-login-manager = {
        enable = true;
      };
    };

    environment.systemPackages = [
      pkgs.kdePackages.kdeconnect-kde
      pkgs.signal-desktop
    ];
  };
}
