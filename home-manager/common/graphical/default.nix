{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./discord.nix
    ./firefox.nix
    ./i3status-rust.nix
    ./i3wm.nix
    ./rofi.nix
    ./xresources.nix
  ];

  home.packages = with pkgs; [
    # Web
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    })

    # Comms
    element-desktop
    slack

    # 3-D Printing
    cura

    # Utils
    flameshot
    gparted
    volumeicon
  ];
}
