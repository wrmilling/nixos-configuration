{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}: {
  services = {
    desktopManager.plasma6 = {
      enable = true;
    };
    xserver.displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
  };
}
