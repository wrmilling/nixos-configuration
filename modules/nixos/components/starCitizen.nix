{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.starCitizen;
in
{
  options.modules.nixos.starCitizen = {
    enable = lib.mkEnableOption "Star Citizen via RSI Launcher";
  };

  config = lib.mkIf cfg.enable {
    programs.rsi-launcher.enable = true;
  };
}
