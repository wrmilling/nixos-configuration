{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.fonts;
in
{
  options.modules.nixos.fonts = {
    enable = lib.mkEnableOption "font packages / settings";
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = [
      pkgs.source-code-pro
      pkgs.font-awesome_4
      pkgs.corefonts
      pkgs.monaspace
    ];
  };
}