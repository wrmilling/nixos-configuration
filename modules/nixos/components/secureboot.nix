{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.secureboot;
in
{
  options.modules.secureboot = {
    enable = lib.mkEnableOption "secureboot packages / settings";
  };

  config = lib.mkIf cfg.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };

    environment.systemPackages = [
      pkgs.sbctl
    ];
  };
}