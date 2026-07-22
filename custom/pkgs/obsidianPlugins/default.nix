# Obsidian community plugins, namespaced here since none of them are
# packaged in nixpkgs. Exposed as pkgs.obsidianPlugins.<name>.
{ pkgs }:
{
  base-board = pkgs.callPackage ./base-board { };
  pandoc = pkgs.callPackage ./pandoc { };
  dataview = pkgs.callPackage ./dataview { };
  advanced-tables = pkgs.callPackage ./advanced-tables { };
}
