{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.nzbget;
in
{
  options.modules.nixos.nzbget = {
    enable = lib.mkEnableOption "NZBGet, started on demand rather than at boot";
  };

  config = lib.mkIf cfg.enable {
    services.nzbget.enable = true;

    # Don't run all the time; start it manually with `systemctl start nzbget`.
    systemd.services.nzbget.wantedBy = lib.mkForce [ ];

    # Let wheel members start/stop nzbget without a sudo password prompt.
    security.polkit.extraConfig = ''
      polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
            action.lookup("unit") == "nzbget.service" &&
            subject.isInGroup("wheel")) {
          return polkit.Result.YES;
        }
      });
    '';
  };
}
