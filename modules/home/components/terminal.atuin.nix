{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.atuin;
in
{
  options.modules.home.terminal.atuin = {
    enable = lib.mkEnableOption "atuin packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.atuin = {
      enable = true;
      package = pkgs.atuin;

      flags = [ "--disable-up-arrow" ];

      settings = {
        auto_sync = true;
        sync_frequency = "1h";
        search_mode = "fuzzy";
      };
    };

    home.packages = [ pkgs.fzf ];
  };
}
