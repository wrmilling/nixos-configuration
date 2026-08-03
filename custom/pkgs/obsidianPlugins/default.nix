# Obsidian community plugins, namespaced here since none of them are
# packaged in nixpkgs. Exposed as pkgs.obsidianPlugins.<name>.
{ pkgs }:
{
  trietment-kanban = pkgs.callPackage ./trietment-kanban { };
  pandoc = pkgs.callPackage ./pandoc { };
  dataview = pkgs.callPackage ./dataview { };
  advanced-tables = pkgs.callPackage ./advanced-tables { };
  tasks = pkgs.callPackage ./tasks { };
  project-manager = pkgs.callPackage ./project-manager { };
}
