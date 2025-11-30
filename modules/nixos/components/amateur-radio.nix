{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.amateurRadio;
in
{
  options.modules.amateurRadio = {
    enable = lib.mkEnableOption "amateur radio packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.chirp
      pkgs.svxlink
    ];
  };
}
