{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.alacritty;
in
{
  options.modules.home.graphical.alacritty = {
    enable = lib.mkEnableOption "alacritty packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      enable = true;
      package = pkgs.alacritty;
      settings = {
        font = {
          normal = {
            family = lib.mkDefault "Monaspace Neon";
            style = lib.mkDefault "Regular";
          };
          bold = {
            family = lib.mkDefault "Monaspace Neon";
            style = lib.mkDefault "Bold";
          };
          italic = {
            family = lib.mkDefault "Monaspace Neon";
            style = "Italic";
          };
          bold_italic = {
            family = lib.mkDefault "Monaspace Neon";
            style = lib.mkDefault "Bold Italic";
          };
          size = lib.mkDefault 11;
        };
        keyboard = {
          bindings = [
            {
              key = "NumpadEnter";
              mods = "None";
              action = "ReceiveChar";
            }
          ];
        };
        terminal.shell = {
          program = "/bin/sh";
          args = [
            "-c"
            "${pkgs.tmux}/bin/tmux"
          ];
        };
      };
    };
  };
}
