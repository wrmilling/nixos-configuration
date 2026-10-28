# Obsidian community plugins, namespaced here since none of them are
# packaged in nixpkgs. Exposed as pkgs.obsidianPlugins.<name>.
{ pkgs }:
{
  pandoc = pkgs.callPackage ./pandoc { };
  dataview = pkgs.callPackage ./dataview { };
  advanced-tables = pkgs.callPackage ./advanced-tables { };
  tasks = pkgs.callPackage ./tasks { };
  tasknotes = pkgs.callPackage ./tasknotes { };
  local-rest-api = pkgs.callPackage ./local-rest-api { };
}
