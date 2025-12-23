{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.wireshark;
in
{
  options.modules.nixos.wireshark = {
    enable = lib.mkEnableOption "wireshark packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.wireshark.enable = true;
  };
}