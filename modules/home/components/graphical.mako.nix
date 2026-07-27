{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.mako;
in
{
  options.modules.home.graphical.mako = {
    enable = lib.mkEnableOption "mako notification daemon packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.mako = {
      enable = true;
      settings = {
        background-color = "#222D31ee";
        text-color = "#d8d8d8";
        border-color = "#1ABB9B";
        border-size = 2;
        border-radius = 0;
        default-timeout = 5000;
        font = "Monaspace Neon 10";
      };
    };
  };
}
