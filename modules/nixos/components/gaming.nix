{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.gaming;
in
{
  options.modules.gaming = {
    enable = lib.mkEnableOption "gaming packages / settings";
  };

  config = lib.mkIf cfg.enable {
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
  };
}