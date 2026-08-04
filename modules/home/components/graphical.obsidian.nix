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

    vaults = {
      personal.enable = lib.mkEnableOption "personal obsidian vault at ~/.obsidian/personal";
      work.enable = lib.mkEnableOption "work obsidian vault at ~/.obsidian/work";
    };
  };

  config = lib.mkIf cfg.enable {
    # Required by the pandoc community plugin, which shells out to it.
    home.packages = [ pkgs.pandoc ];

    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;

      defaultSettings.communityPlugins = [
        { pkg = pkgs.obsidianPlugins.pandoc; }
        { pkg = pkgs.obsidianPlugins.dataview; }
        { pkg = pkgs.obsidianPlugins.advanced-tables; }
        { pkg = pkgs.obsidianPlugins.tasks; }
        { pkg = pkgs.obsidianPlugins.tasknotes; }
      ];

      defaultSettings.cssSnippets = [
        { source = ./assets/tasknotes-kanban.css; }
      ];

      vaults = lib.mkMerge [
        (lib.mkIf cfg.vaults.personal.enable {
          personal.target = ".obsidian/personal";
        })
        (lib.mkIf cfg.vaults.work.enable {
          work.target = ".obsidian/work";
        })
      ];
    };
  };
}
