{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.printing;
in
{
  options.modules.nixos.printing = {
    enable = lib.mkEnableOption "printing packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.printing.enable = true;
    services.avahi.enable = true;
    services.avahi.nssmdns4 = true;
  };
}