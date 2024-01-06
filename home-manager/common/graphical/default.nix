{pkgs, ...}: {
  imports = [
    ./alacritty.nix
    ./firefox.nix
    ./rofi.nix
    ./xresources.nix
  ];

  home.packages = with pkgs;
    lib.mkMerge [
      (lib.mkIf stdenv.isx86_64 [
        slack
      ])
      (lib.mkIf stdenv.isAarch64 [
        ])
      [
        element-desktop
        cura
        flameshot
        gparted
        # volumeicon
      ]
    ];
}
