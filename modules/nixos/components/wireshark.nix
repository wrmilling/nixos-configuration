{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.wireshark;
in
{
  options.modules.wireshark = {
    enable = lib.mkEnableOption "wireshark packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.wireshark.enable = true;
  };
}