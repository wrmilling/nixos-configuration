{ pkgs, lib, config, ... }:

{
  home.packages = with pkgs; [
    swaybg
  ];

  wayland.windowManager.sway = {
    enable = true;
    package = null;

    config = let
      mod = "Mod4";
      terminal = "${pkgs.alacritty}/bin/alacritty";
      menu = "${pkgs.rofi-wayland}/bin/rofi -show drun";
      pactl = "${pkgs.pulseaudio}/bin/pactl";
    in {
      inherit terminal menu;
      modifier = mod;

      fonts = {
        names = ["Public Sans"];
        size = 9.0;
        style = "SemiBold";
      };

      gaps.inner = 2;
      gaps.smartGaps = true;
      window.hideEdgeBorders = "smart";

      keybindings = lib.mkOptionDefault {
        "XF86MonBrightnessDown" = "exec light -U 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
        "XF86MonBrightnessUp" = "exec light -A 5 && light -G | cut -d'.' -f1 > $WOBSOCK";
        "XF86AudioRaiseVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ +4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
        "XF86AudioLowerVolume" = "exec ${pactl} set-sink-volume @DEFAULT_SINK@ -4% && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";
        "XF86AudioMute" = "exec ${pactl} set-sink-mute @DEFAULT_SINK@ toggle && ${pactl} get-sink-volume @DEFAULT_SINK@ | head -n1 | awk '{print substr($5, 1, length($5) - 1)}' > $WOBSOCK";

        "Print" = "exec ${pkgs.grim}/bin/grim";
        "Shift+Print" = "exec ${pkgs.grim}/bin/grim -g \"$(${pkgs.slurp}/bin/slurp)\"";
      };

      input."type:keyboard" = {
        xkb_options = "caps:ctrl_modifier";
      };

      input."type:touchpad" = {
        click_method = "clickfinger";
        middle_emulation = "disabled";
        natural_scroll = "enabled";
      };

      bars = [
        {command = "${pkgs.i3status-rust}/bin/i3status-rs";}
      ];

      startup = [
        {command = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";}
      ];
    };
  };

  services.swayidle = let
    lockNow = "${pkgs.swaylock}/bin/swaylock -f";
    suspendNow = "${config.systemd.user.systemctlPath} suspend";
    isOnBattery = pkgs.writeShellScript "is-on-battery" ''
      [ $(cat /sys/class/power_supply/dc-charger/online) = "0" ] || exit 1
    '';
  in {
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
      PartOf = ["graphical-session.target"];
    };
    Service = {
      ExecStart = "${pkgs.swaybg}/bin/swaybg -i ${./sway-bg.png} -m fit -c #000000";
      Type = "simple";
    };
    Install.WantedBy = ["sway-session.target"];
  };

  services.clipman.enable = true;
}
