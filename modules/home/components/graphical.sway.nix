{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.sway;
in
{
  options.modules.home.graphical.sway = {
    enable = lib.mkEnableOption "sway tiling window manager packages / settings";
  };

  config = lib.mkIf cfg.enable {
    modules.home.graphical.waybar.enable = true;
    modules.home.graphical.mako.enable = true;
    modules.home.graphical.fuzzel.enable = true;

    home.packages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
    ];

    programs.swaylock = {
      enable = true;
      settings = {
        color = "222D31";
        indicator-idle-visible = false;
        indicator-radius = 100;
        line-color = "1ABB9B";
        show-failed-attempts = true;
      };
    };

    services.swayidle = {
      enable = true;
      timeouts = [
        {
          timeout = 300;
          command = "${pkgs.swaylock}/bin/swaylock -f";
        }
        {
          timeout = 600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
      events = {
        before-sleep = "${pkgs.swaylock}/bin/swaylock -f";
        lock = "${pkgs.swaylock}/bin/swaylock -f";
      };
    };

    wayland.windowManager.sway = {
      enable = true;
      wrapperFeatures.gtk = true;

      config = {
        modifier = "Mod4";
        terminal = "alacritty";
        menu = "fuzzel";

        # waybar replaces the built-in swaybar
        bars = [ ];

        gaps.inner = 5;

        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "enabled";
          };
        };

        output."*".bg = "${./assets/pinebook-wallpaper.jpg} fill";

        keybindings =
          let
            modifier = "Mod4";
          in
          lib.mkOptionDefault {
            "${modifier}+Return" = "exec alacritty";
            "${modifier}+d" = "exec fuzzel";
            "${modifier}+Shift+q" = "kill";
            "${modifier}+Shift+c" = "reload";
            "${modifier}+Shift+e" = "exec swaynag -t warning -m 'Exit sway?' -b 'Yes' 'swaymsg exit'";
            "${modifier}+l" = "exec swaylock -f";
            "Print" = "exec grim -g \"$(slurp)\" - | wl-copy";
          };
      };
    };
  };
}
