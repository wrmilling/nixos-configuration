{ pkgs, lib, config, ... }: 

{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = lib.mkDefault "SourceCodePro";
          style = lib.mkDefault "Regular";
        };
        bold = {
          family = lib.mkDefault "SourceCodePro";
          style = lib.mkDefault "Bold";
        };
        italic = {
          family = lib.mkDefault "SourceCodePro";
          style = "Italic";
        };
        bold_italic = {
          family = lib.mkDefault "SourceCodePro";
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
