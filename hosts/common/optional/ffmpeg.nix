{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg.override {
      withV4l2 = true;
    }
  ];
}
