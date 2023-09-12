{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    pw-volume
  ];

  sound.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
}
