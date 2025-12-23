{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.machineType.desktop;
in
{
  options.modules.machineType.desktop = {
    enable = lib.mkEnableOption "desktop NixOS modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      nixos.base.enable = true;
      nixos.audio.enable = true;
      nixos.filesystem.enable = true;
      nixos.fonts.enable = true;
      nixos.graphical.enable = true;
      nixos.network.enable = true;
      nixos.plasma6.enable = true;
    };
  };
}
