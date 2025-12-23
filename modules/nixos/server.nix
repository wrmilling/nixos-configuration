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
      nixos.base.enable = true;
      nixos.chrony.enable = true;
      nixos.filesystem.enable = true;
      nixos.sshd.enable = true;
    };
  };
}
