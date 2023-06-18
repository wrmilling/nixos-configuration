{ pkgs, ... }: 

{
  imports = [
    ./alacritty.nix
  ];
  home.packages = with pkgs; [
    # Web
    (vivaldi.override {
      proprietaryCodecs = true;
      enableWidevine = false;
    })

    # Comms
    element-desktop
    discord
    slack

    # 3-D Printing
    cura

    # Utils
    flameshot
    gparted
    volumeicon
  ];
}