{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.amateurRadio;
in
{
  options.modules.nixos.amateurRadio = {
    enable = lib.mkEnableOption "amateur radio packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.chirp
      pkgs.svxlink
    ];
  };
}
