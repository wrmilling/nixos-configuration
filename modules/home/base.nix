{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.home.base;
in
{
  imports = lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./components);

  options.modules.home.base = {
    enable = lib.mkEnableOption "base Home-Manager configuration";
  };

  config = lib.mkIf cfg.enable {
    # TODO: Consolidate shared modules to default
    modules = { };
  };
}
