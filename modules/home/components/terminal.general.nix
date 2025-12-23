{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.general;
in
{
  options.modules.home.terminal.general = {
    enable = lib.mkEnableOption "general terminal packages / settings";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.hut
      pkgs.shellclear
      pkgs.lynx
      pkgs.viddy
      pkgs.silver-searcher
      pkgs.magic-wormhole-rs
      pkgs.any-nix-shell
      pkgs.fzf
    ];
  };
}
