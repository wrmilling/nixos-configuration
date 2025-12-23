{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.server;
in
{
  options.modules.homeType.server = {
    enable = lib.mkEnableOption "server home-manager modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      home.base.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.vim.enable = true;
    };
  };
}