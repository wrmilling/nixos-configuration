{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [
    swaybg
    glib
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;

    config =
      let
        mod = "Mod4";
        terminal = "${pkgs.alacritty}/bin/alacritty";
        menu = "${pkgs.rofi-wayland}/bin/rofi -show drun";
        pactl = "${pkgs.pulseaudio}/bin/pactl";
      in
      {
        inherit terminal menu;
        modifier = mod;

        fonts = {
          names = [ "Public Sans" ];
          size = 10.0;
          style = "SemiBold";
        };

        gaps = {
          inner = 10;
          outer = -2;
          smartGaps = true;
        };

        window = {
          hideEdgeBorders = "smart";
          titlebar = false;
        };

        keybindings = lib.mkOptionDefault {
          "XF86MonBrightnessDown" = "exec light -U 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
          "XF86MonBrightnessUp" = "exec light -A 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
          "XF86AudioRaiseVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
          "XF86AudioLowerVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
          "XF86AudioMute" = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";

          "${mod}+space" = "exec --no-startup-id ${menu}";
          "Print" = "exec ${pkgs.grim}/bin/grim";
          "Shift+Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"";
        };

        input."type:keyboard" = {
          xkb_options = "caps:ctrl_modifier";
        };

        input."type:touchpad" = {
          click_method = "button_areas";
          tap = "enabled";
          middle_emulation = "disabled";
          natural_scroll = "enabled";
        };

        bars = [
          {
            statusCommand = "${pkgs.i3status-rust}/bin/i3status-rs";
            position = "top";
            trayOutput = "eDP-1";
            fonts = {
              size = 11.0;
            };
            colors = {
              background = "#222D31";
              statusline = "#F9FAF9";
              separator = "#454947";
              focusedWorkspace = {
                border = "#F9FAF9";
                background = "#16a085";
                text = "#292F34";
              };
              activeWorkspace = {
                border = "#595B5B";
                background = "#353836";
                text = "#FDF6E3";
              };
              inactiveWorkspace = {
                border = "#595B5B";
                background = "#222D31";
                text = "#EEE8D5";
              };
              bindingMode = {
                border = "#16a085";
                background = "#2C2C2C";
                text = "#F9FAF9";
              };
              urgentWorkspace = {
                border = "#16a085";
                background = "#FDF6E3";
                text = "#E5201D";
              };
            };
          }
        ];

        startup = [ { command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"; } ];
      };
  };

  services.swayidle =
    let
      lockNow = "${pkgs.swaylock}/bin/swaylock -f";
      suspendNow = "${config.systemd.user.systemctlPath} suspend";
      isOnBattery = pkgs.writeShellScript "is-on-battery" ''
        [ $(cat /sys/class/power_supply/dc-charger/online) = "0" ] || exit 1
      '';
    in
    {
      enable = true;
      timeouts = [
        {
          timeout = 5 * 60;
          command = "${isOnBattery} && ${lockNow}";
        }
        {
          timeout = 15 * 60;
          command = "${lockNow}";
        }
      ];
      events = [
        {
          event = "before-sleep";
          command = "${lockNow}";
        }
        {
          event = "lock";
          command = "${lockNow}";
        }
      ];
    };

  services.mako = {
    enable = true;
    font = "sans-serif 9";
    anchor = "bottom-right";
    padding = "10";
    borderRadius = 5;
    backgroundColor = "#eff1f5";
    textColor = "#4c4f69";
    borderColor = "#1e66f5";
    progressColor = "over #ccd0da";

    extraConfig = ''
      [urgency=high]
      border-color=#fe640b
    '';
  };

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      font = "sans-serif";
    };
  };

  systemd.user.services.swaybg = {
    Unit = {
      Description = "swaybg background service";
      Documentation = "man:swaybg(1)";
      PartOf = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${./sway-bg.png} -m fit -c #000000";
      Type = "simple";
    };
    Install.WantedBy = [ "sway-session.target" ];
  };

  gtk = {
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Adwaita";
      package = pkgs.gnome.adwaita-icon-theme;
    };
  };

  services.clipman.enable = true;
}
