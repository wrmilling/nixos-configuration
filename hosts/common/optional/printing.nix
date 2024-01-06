{
  config,
  lib,
  pkgs,
  ...
}: {
  services.printing.enable = true;
  services.avahi.enable = true;
  services.avahi.nssmdns = true;
}
