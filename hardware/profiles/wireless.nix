{ config, pkgs, lib, ... }:
{
  # We don't want blueman installed in the global scope.
  # See <services/desktops/blueman.nix>
  # services.blueman.enable = true;
  services.dbus.packages = [ pkgs.blueman ];
  systemd.packages = [ pkgs.blueman ];

  # Bluetooth
  hardware.bluetooth.enable = true;

  # Add a user service for blueman
  systemd.user.services = lib.mkMerge [
    (config.lib.w4cbe.userServiceFromAutostart { name = "blueman"; package = pkgs.blueman; })
  ];
}
