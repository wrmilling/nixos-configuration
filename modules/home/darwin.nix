{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.darwin;
in
{
  options.modules.homeType.darwin = {
    enable = lib.mkEnableOption "darwin home-manager modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      home.base.enable = true;
      home.graphical.alacritty.enable = true;
      home.graphical.xresources.enable = true;
      home.terminal.atuin.enable = true;
      home.terminal.development.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.general.enable = true;
      home.terminal.git.enable = true;
      home.terminal.gpg.darwin.enable = true;
      home.terminal.k8s-utils.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.tmux.enable = true;
      home.terminal.vim.enable = true;
    };

    home.packages = [
      pkgs.cloudfoundry-cli
      pkgs.google-cloud-sdk
      pkgs.rancher
      pkgs.slides-git
      pkgs.graph-easy
    ];
  };
}