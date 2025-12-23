{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.personal;
in
{
  options.modules.homeType.personal = {
    enable = lib.mkEnableOption "personal home-manager modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      home.base.enable = true;
      home.terminal.atuin.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.general.enable = true;
      home.terminal.git.enable = true;
      home.terminal.gpg.enable = true;
      home.terminal.k8s-utils.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.tmux.enable = true;
      home.terminal.vim.enable = true;
      home.graphical.alacritty.enable = true;
      home.graphical.discord.enable = true;
      home.graphical.firefox.enable = true;
      home.graphical.keybase.enable = true;
      home.graphical.minecraft-client.enable = true;
      home.graphical.xresources.enable = true;
    };

    home.packages = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isx86_64 [ pkgs.slack ])
      (lib.mkIf pkgs.stdenv.isAarch64 [ ])
      [
        pkgs.element-desktop
        # cura
        pkgs.flameshot
        pkgs.gparted
        # volumeicon
        pkgs.keepassxc
        pkgs.vlc
        pkgs.hugo
      ]
    ];
  };
}