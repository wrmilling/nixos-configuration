{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.minecraft-client;
in
{
  options.modules.home.terminal.minecraft-client = {
    enable = lib.mkEnableOption "minecraft-client packages / settings";
  };

  config = lib.mkIf cfg.enable {
    # TODO: Eliminate this for being one line?
    home.packages = [ pkgs.prismlauncher ];
  };
}
