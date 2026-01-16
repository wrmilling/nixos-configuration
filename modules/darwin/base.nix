{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.darwin.base;
in
{
  imports = lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ../nixos/components);

  options.modules.darwin.base = {
    enable = lib.mkEnableOption "base darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    # Default 
    modules = { };
  };
}
