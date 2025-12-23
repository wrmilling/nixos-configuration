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
      nixos.base.enable = true;
      nixos.audio.enable = true;
      nixos.bluetooth.enable = true;
      nixos.filesystem.enable = true;
      nixos.fonts.enable = true;
      nixos.graphical.enable = true;
      nixos.network.enable = true;
      nixos.plasma6.enable = true;
    };

    networking.networkmanager.enable = true;
  };
}
