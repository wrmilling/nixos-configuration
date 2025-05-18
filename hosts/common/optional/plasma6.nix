{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}:
{
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
}
