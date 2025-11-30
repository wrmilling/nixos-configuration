{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.machineType.laptop;
in
{
  options.modules.machineType.laptop = {
    enable = lib.mkEnableOption "laptop NixOS modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      base.enable = true;
      audio.enable = true;
      bluetooth.enable = true;
      filesystem.enable = true;
      fonts.enable = true;
      graphical.enable = true;
      network.enable = true;
      plasma6.enable = true;
    };

    networking.networkmanager.enable = true;
  };
}
