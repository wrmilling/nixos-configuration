{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.home.graphical.vr;
in
{
  options.modules.home.graphical.vr = {
    enable = lib.mkEnableOption "VR (xr-video-player / mpv) packages / settings";
  };

  config = lib.mkIf cfg.enable {
    # xr-video-player picks this up via `--mpv-profile xrvp-perf`.
    # display-fps-override matches the Index panel's chosen mode (2880x1600@120)
    # since mpv can't query real vsync timing through an offscreen FBO render.
    xdg.configFile."mpv/mpv.conf".text = ''
      [xrvp-perf]
      profile=fast
      hwdec=auto-safe
      display-fps-override=120
    '';
  };
}
