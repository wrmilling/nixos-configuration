{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.onedrive;
in
{
  options.modules.nixos.onedrive = {
    enable = lib.mkEnableOption "onedrive service and onedrivegui package";
  };

  config = lib.mkIf cfg.enable {
    services.onedrive.enable = true;

    environment.systemPackages = [ pkgs.onedrivegui ];
  };
}
