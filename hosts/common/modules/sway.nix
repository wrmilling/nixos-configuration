{
  config,
  pkgs,
  lib,
  callPackage,
  ...
}:
{
  programs.sway = {
    enable = true;
    extraSessionCommands = ''
      export QT_QPA_PLATFORM=wayland
      export _JAVA_AWT_WM_NONREPARENTING=1
      export MOZ_DBUS_REMOTE=1
      export NIXOS_OZONE_WL=1
    '';
    extraPackages = with pkgs; [
      swaylock
      swayidle
      rofi-wayland
      xwayland
      qt5.qtwayland
    ];
    wrapperFeatures.gtk = true;
  };

  services.udisks2.enable = true;
  security.rtkit.enable = true;
  programs.light.enable = true;
  programs.thunar.enable = true;

  fonts = {
    fonts = with pkgs; [
      public-sans
      open-sans
      noto-fonts
      noto-fonts-emoji
      (nerdfonts.override { fonts = [ "NerdFontsSymbolsOnly" ]; })
      font-awesome
    ];

    fontconfig = {
      defaultFonts = {
        monospace = [ "Noto Sans Mono" ];
        sansSerif = [
          "Public Sans"
          "Open Sans"
          "Noto Sans"
        ];
        serif = [ "Noto Serif" ];
      };
    };
  };

  services.gvfs = {
    enable = true;
    package = lib.mkForce pkgs.gnome3.gvfs;
  };
}
