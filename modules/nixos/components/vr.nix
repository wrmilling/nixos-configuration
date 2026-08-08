{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.vr;
in
{
  options.modules.nixos.vr = {
    enable = lib.mkEnableOption "VR (Monado OpenXR runtime) packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.monado = {
      enable = true;
      # /etc default plus an active per-user override, since a prior SteamVR
      # install may have already written its own ~/.config/openxr/1/active_runtime.json.
      defaultRuntime = true;
      forceDefaultRuntime = true;
      # cap_sys_nice for async reprojection, granted directly to
      # monado-service via a NixOS security wrapper - not routed through
      # Steam's sandbox at all. See: https://wiki.vronlinux.org/docs/distros/nixos/
      highPriority = true;
    };

    # Lighthouse tracking (Index/Vive base stations) via SteamVR's driver
    # instead of Monado's default libsurvive.
    systemd.user.services.monado.environment.STEAMVR_LH_ENABLE = "1";

    # Let OpenXR-native games launched through Steam's sandbox see the
    # host's active runtime (Monado) instead of requiring SteamVR's own.
    # Assumes modules.nixos.gaming.enable (or another `programs.steam.enable`)
    # is also set somewhere on this host.
    programs.steam.package = pkgs.steam.override {
      extraProfile = ''
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
        unset TZ
      '';
    };
  };
}
