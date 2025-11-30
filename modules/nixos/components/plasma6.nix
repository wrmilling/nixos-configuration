{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.plasma6;
in
{
  options.modules.plasma6 = {
    enable = lib.mkEnableOption "plasma6 packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services = {
      desktopManager.plasma6 = {
        enable = true;
      };
      displayManager.sddm = {
        enable = true;
        wayland.enable = true;
      };
    };

    environment.systemPackages = [
      pkgs.kdePackages.kdeconnect-kde
      pkgs.signal-desktop
    ];
  };
}