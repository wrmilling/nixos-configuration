{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.graphical.waybar;
in
{
  options.modules.home.graphical.waybar = {
    enable = lib.mkEnableOption "waybar status bar packages / settings";
  };

  config = lib.mkIf cfg.enable {
    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 32;
          modules-left = [
            "sway/workspaces"
            "sway/mode"
          ];
          modules-center = [ "sway/window" ];
          modules-right = [
            "tray"
            "pulseaudio"
            "network"
            "battery"
            "clock"
          ];

          "sway/workspaces" = {
            disable-scroll = true;
          };

          tray = {
            spacing = 8;
          };

          pulseaudio = {
            format = "{icon} {volume}%";
            format-muted = "  muted";
            format-icons = {
              default = [
                ""
                ""
                ""
              ];
            };
            on-click = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            on-scroll-up = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
            on-scroll-down = "${pkgs.wireplumber}/bin/wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          };

          network = {
            format-wifi = "  {essid} ({signalStrength}%)";
            format-ethernet = "  {ifname}";
            format-disconnected = "⚠ disconnected";
          };

          battery = {
            format = "{icon} {capacity}%";
            format-charging = "  {capacity}%";
            format-icons = [
              ""
              ""
              ""
              ""
              ""
            ];
            states = {
              warning = 30;
              critical = 15;
            };
          };

          clock = {
            format = "{:%H:%M  %a %b %d}";
            tooltip-format = "{:%Y-%m-%d}";
          };
        };
      };

      style = ''
        * {
          font-family: "Monaspace Neon", sans-serif;
          font-size: 13px;
        }

        window#waybar {
          background-color: #222D31;
          color: #d8d8d8;
        }

        #workspaces button {
          padding: 0 8px;
          color: #d8d8d8;
        }

        #workspaces button.focused {
          background-color: #1ABB9B;
          color: #222D31;
        }

        #battery, #pulseaudio, #network, #clock, #tray {
          padding: 0 10px;
        }

        #battery.warning {
          color: #f7ca88;
        }

        #battery.critical {
          color: #ab4642;
        }
      '';
    };
  };
}
