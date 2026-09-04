{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.graphical.fuzzel;
in
{
  options.modules.home.graphical.fuzzel = {
    enable = lib.mkEnableOption "fuzzel application launcher packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.fuzzel = {
      enable = true;
      settings = {
        main = {
          font = "Monaspace Neon:size=11";
          terminal = "alacritty";
        };
        colors = {
          background = "222d31ee";
          text = "d8d8d8ff";
          match = "1abb9bff";
          selection = "1abb9b44";
          selection-text = "d8d8d8ff";
          border = "1abb9bff";
        };
        border = {
          width = 2;
          radius = 0;
        };
      };
    };
  };
}
