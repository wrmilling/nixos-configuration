{ config, lib, pkgs, ... }:

{
  lib.w4cbe = {
    userServiceFromAutostart =
      { name
      , type ? "simple"
      , package ? "/run/current-system/sw"
      }:
      let
        path = "${package}/etc/xdg/autostart/${name}.desktop";
        script = pkgs.writeShellScript "run.xdg.autostart.${name}" ''
          source /etc/profile
          PATH="${package}/bin:$PATH"
          exec ${pkgs.dex}/bin/dex --wait "${path}"
        '';
      in
      {
        "xdg.autostart.${name}" = {
          enable = true;
          serviceConfig = {
            Type = type;
            Restart = lib.mkIf (type != "oneshot") "always";
            RestartSec= lib.mkIf (type != "oneshot") "5";
            ExecStart = "${pkgs.with-profile} ${script}";
          };
          unitConfig = {
            ConditionPathExists = "/run/user/%U";
          };
          wantedBy = [ "graphical-session.target" ];
          bindsTo = [ "graphical-session.target" ];
          restartTriggers = [
            path
            script
          ];
        };
      }
    ;
  };
}
