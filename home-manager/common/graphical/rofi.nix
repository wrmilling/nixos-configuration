{
  pkgs,
  lib,
  config,
  ...
}: {
  home.packages = with pkgs; [];
  home.file."rofi-config" = {
    target = ".config/rofi/config.rasi";
    text = ''
      configuration {
        modes: "drun,run,ssh,combi";
        timeout {
            action: "kb-cancel";
            delay:  0;
        }
        filebrowser {
            directories-first: true;
            sorting-method:    "name";
        }
      }
      @theme "Monokai"
    '';
  };
}
