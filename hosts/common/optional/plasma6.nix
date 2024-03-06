{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}: {
  services.xserver = {
    desktopManager.plasma6 = {
      enable = true;
    };
    displayManager.sddm = {
      enable = true;
    };
  };
  services.xserver.displayManager.sddm.wayland.enable = true;
}
