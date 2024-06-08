{ config, lib, ... }:
{
  # Visual boot
  boot.initrd.systemd.enable = true;
  boot.plymouth.enable = true;
  boot.kernelParams = [ "quiet" ];
}
