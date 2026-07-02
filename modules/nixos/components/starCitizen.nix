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

    nix.settings = {
      substituters = [ "https://nix-citizen.cachix.org" ];
      trusted-public-keys = [ "nix-citizen.cachix.org-1:lPMkWc2X8XD4/7YPEEwXKKBg+SVbYTVrAaLA2wQTKCo=" ];
    };
  };
}
