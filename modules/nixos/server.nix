{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.machineType.server;
in
{
  options.modules.machineType.server = {
    enable = lib.mkEnableOption "server NixOS modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      base.enable = true;
      chrony.enable = true;
      filesystem.enable = true;
      sshd.enable = true;
    };
  };
}
