{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.chrony;
in
{
  options.modules.chrony = {
    enable = lib.mkEnableOption "chrony packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.chrony = {
      enable = true;
      enableNTS = true;
      servers = [
        "virginia.time.system76.com"
        "ohio.time.system76.com"
        "oregon.time.system76.com"
      ];
    };
  };
}