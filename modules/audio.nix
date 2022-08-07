{ config, lib, pkgs, ... }:

{
  sound.enable = true;

  # Audio configuration
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull; # Full for bluetooth audio support.

  # Ensure the xdg autostart file is ran.
  systemd.user.services =
    (config.lib.w4cbe.userServiceFromAutostart { name = "pulseaudio"; type = "oneshot"; })
  ;
}
