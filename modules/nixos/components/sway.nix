{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.sway;
in
{
  options.modules.nixos.sway = {
    enable = lib.mkEnableOption "sway tiling Wayland compositor packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.sway = {
      enable = true;
      wrapperFeatures.gtk = true;
    };

    # Needed for screen-sharing/screenshot portals under a wlroots compositor.
    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    environment.systemPackages = [
      pkgs.polkit_gnome
      pkgs.networkmanagerapplet
    ];
  };
}
