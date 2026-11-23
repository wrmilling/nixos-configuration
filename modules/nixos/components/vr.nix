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
    environment.systemPackages = [
      pkgs.xr-video-player
      pkgs.wayvr
    ];

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

    # STEAMVR_LH_ENABLE segfaults monado-service (null HmdDriverFactory call
    # in steamvr_lh_create_devices); libsurvive tracks the Index fine without it.

    # Mercury (camera hand tracking) segfaults in onnxruntime: nixpkgs' monado
    # doesn't ship its ONNX models, so the model load fails and the driver
    # still tries to run inference on the resulting invalid session.
    systemd.user.services.monado.environment = {
      LH_HANDTRACKING = "OFF";
      # Graphics compositor: draws overlay layers as geometry, so WayVR at 120% costs less than compute at 90%.
      XRT_COMPOSITOR_COMPUTE = "0";
      XRT_COMPOSITOR_SCALE_PERCENTAGE = "120";
      # Fail instead of falling back to a desktop window when the headset isn't ready.
      XRT_COMPOSITOR_FORCE_WAYLAND_DIRECT = "1";
    };

    # USB autosuspend on Valve (Index) devices can drop tracking mid-session.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="28de", TEST=="power/control", ATTR{power/control}="on"
      # Let the video group pin amdgpu clocks while Monado runs (iGPU memory-clock switches stall frames).
      ACTION=="add", SUBSYSTEM=="drm", KERNEL=="card[0-9]", DRIVERS=="amdgpu", TEST=="device/power_dpm_force_performance_level", RUN+="${pkgs.coreutils}/bin/chgrp video /sys%p/device/power_dpm_force_performance_level", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys%p/device/power_dpm_force_performance_level"
    '';

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
