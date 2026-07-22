{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.obsidian;
in
{
  options.modules.home.graphical.obsidian = {
    enable = lib.mkEnableOption "obsidian packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;

      defaultSettings.communityPlugins = [
        { pkg = pkgs.obsidianPlugins.base-board; }
        { pkg = pkgs.obsidianPlugins.pandoc; }
        { pkg = pkgs.obsidianPlugins.dataview; }
        { pkg = pkgs.obsidianPlugins.advanced-tables; }
      ];
    };
  };
}
