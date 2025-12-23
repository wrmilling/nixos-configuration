{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.pinebook;
in
{
  options.modules.homeType.pinebook = {
    enable = lib.mkEnableOption "pinebook home-manager modules";
  };

  # ../common/terminal
  #   ../common/graphical
  #   ../common/optional/legcord.nix
  #   ../common/optional/gaming-arm.nix
  #   ../common/optional/k8s-utils.nix
  #   ../common/optional/keybase.nix

  # imports = [
  #   ./atuin.nix
  #   ./fish.nix
  #   ./general.nix
  #   ./git.nix
  #   ./gpg.nix
  #   ./starship.nix
  #   ./tmux.nix
  #   ./vim.nix
  # ];
  


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
      home.graphical.firefox.enable = true;
      home.graphical.keybase.enable = true;
      home.graphical.legcord.enable = true;
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