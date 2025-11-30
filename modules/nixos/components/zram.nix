{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.zram;
in
{
  options.modules.zram = {
    enable = lib.mkEnableOption "zram packages / settings";
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };
  };
}