{ pkgs, lib, config, ... }: 

{
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        normal = {
          family = "SourceCodePro";
          style = "Regular";
        };
        bold = {
          family = "SourceCodePro";
          style = "Bold";
        };
        italic = {
          family = "SourceCodePro";
          style = "Italic";
        };
        bold_italic = {
          family = "SourceCodePro";
          style = "Bold Italic";
        };
        size = 11;
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
