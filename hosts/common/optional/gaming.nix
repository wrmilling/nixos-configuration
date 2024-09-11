{
  config,
  lib,
  pkgs,
  ...
}:
{
  programs.steam.enable = true;

  networking.firewall.allowedTCPPorts = [
    27036 # Steam Remote Play
    27037 # Steam Remote Play
  ];

  networking.firewall.allowedUDPPorts = [
    27031 # Steam Remote Play
    27036 # Steam Remote Play
  ];

  environment.systemPackages = [
    pkgs.lutris
    pkgs.heroic
    pkgs.protonup-qt
  ];
}
