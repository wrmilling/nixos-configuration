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
    enable = lib.mkEnableOption "distraction-free sway session for writing / focused work";
  };

  config = lib.mkIf cfg.enable {
    modules.home.graphical.mako.enable = true;
    modules.home.graphical.fuzzel.enable = true;

    home.packages = [
      pkgs.grim
      pkgs.slurp
      pkgs.wl-clipboard
      pkgs.swayosd
      pkgs.bluetuith
      pkgs.pulsemixer
      pkgs.networkmanager
      pkgs.brightnessctl
      pkgs.playerctl
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

        # No bar: nothing stays on screen unless explicitly invoked.
        bars = [ ];

        window = {
          titlebar = false;
          border = 1;
        };

        floating.titlebar = false;

        input = {
          "type:touchpad" = {
            tap = "enabled";
            natural_scroll = "enabled";
            dwt = "enabled";
          };
        };

        output."*".bg = "${./assets/pinebook-wallpaper.jpg} fill";

        startup = [
          { command = "alacritty"; }
          { command = "${pkgs.swayosd}/bin/swayosd-server"; }
        ];

        floating.criteria = [
          { app_id = "float-nmtui"; }
          { app_id = "float-bluetuith"; }
          { app_id = "float-pulsemixer"; }
        ];

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

            # On-demand TUI scratchpads: nothing runs unless invoked.
            "${modifier}+n" = "exec alacritty --class float-nmtui -e nmtui";
            "${modifier}+b" = "exec alacritty --class float-bluetuith -e bluetuith";
            "${modifier}+a" = "exec alacritty --class float-pulsemixer -e pulsemixer";

            "XF86AudioRaiseVolume" = "exec ${pkgs.swayosd}/bin/swayosd-client --output-volume raise";
            "XF86AudioLowerVolume" = "exec ${pkgs.swayosd}/bin/swayosd-client --output-volume lower";
            "XF86AudioMute" = "exec ${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle";
            "XF86MonBrightnessUp" = "exec ${pkgs.swayosd}/bin/swayosd-client --brightness raise";
            "XF86MonBrightnessDown" = "exec ${pkgs.swayosd}/bin/swayosd-client --brightness lower";
            "XF86AudioPlay" = "exec ${pkgs.playerctl}/bin/playerctl play-pause";
            "XF86AudioNext" = "exec ${pkgs.playerctl}/bin/playerctl next";
            "XF86AudioPrev" = "exec ${pkgs.playerctl}/bin/playerctl previous";
          };
      };
    };
  };
}
