{ config, lib, pkgs, ... }:

{
  sound.enable = true;

  # Audio configuration
  hardware.pulseaudio.enable = true;
  hardware.pulseaudio.package = pkgs.pulseaudioFull; # Full for bluetooth audio support.
}
