{
  pkgs,
  lib,
  config,
  ...
}: {
  programs.alacritty = {
    enable = true;
    package = pkgs.unstable.alacritty;
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
      shell = {
        program = "/bin/sh";
        args = [
          "-c"
          "${pkgs.tmux}/bin/tmux"
        ];
      };
    };
  };
}
