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
    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;

      defaultSettings.app = {
        readableLineLength = true;
        showLineNumber = true;
        tabSize = 2;
      };

      defaultSettings.corePlugins = [
        "backlink"
        "bases"
        "bookmarks"
        "canvas"
        "command-palette"
        {
          name = "daily-notes";
          settings.template = "Backmatter/Templates/Daily";
        }
        "editor-status"
        "file-explorer"
        "file-recovery"
        "global-search"
        "graph"
        "note-composer"
        "outgoing-link"
        "outline"
        "page-preview"
        "properties"
        "slash-command"
        "slides"
        "switcher"
        "sync"
        "tag-pane"
        {
          name = "templates";
          settings.folder = "Backmatter/Templates";
        }
        "webviewer"
        "word-count"
        "workspaces"
      ];

      defaultSettings.communityPlugins = [
        { pkg = pkgs.obsidianPlugins.trietment-kanban; }
        { pkg = pkgs.obsidianPlugins.pandoc; }
        { pkg = pkgs.obsidianPlugins.dataview; }
        { pkg = pkgs.obsidianPlugins.advanced-tables; }
        { pkg = pkgs.obsidianPlugins.tasks; }
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
