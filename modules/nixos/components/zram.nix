{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.zram;
in
{
  options.modules.nixos.zram = {
    enable = lib.mkEnableOption "zram packages / settings";
  };

  config = lib.mkIf cfg.enable {
    zramSwap = {
      enable = true;
      algorithm = "zstd";
    };
  };
}