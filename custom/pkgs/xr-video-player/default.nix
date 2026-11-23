{
  lib,
  stdenv,
  fetchFromGitea,
  cmake,
  pkg-config,
  SDL2,
  libGL,
  libdrm,
  wayland,
  libepoxy,
  glib,
  pipewire,
  mpv-unwrapped,
  glm,
  openxr-loader,
}:
let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version rev;
in
stdenv.mkDerivation {
  pname = "xr-video-player";
  inherit version;

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "yoshino";
    repo = "xr-video-player";
    inherit rev;
    hash = versions.hash;
  };

  patches = [
    # Render mpv straight to the texture; the 4x MSAA pass only added memory traffic.
    ./mpv-no-msaa.patch
    # Give mpv a DRM render node so VA-API decodes zero-copy (dmabuf), not via vaapi-copy.
    ./mpv-vaapi-zero-copy.patch
    # Inset each cube face (not just the atlas border) so edges don't bleed in the neighbouring face.
    ./cube-face-seams.patch
    # --equirect360: play 360 equirect video as a Monado equirect2 layer (no cube conversion).
    ./equirect-layer.patch
    # Keep the XR loop at full rate: mpv no longer sleeps under the shared EGL lock,
    # and the per-eye self-blit and unused depth swapchains are gone.
    ./xr-loop-unblock.patch
    # Desktop preview window is opt-in (--preview); redrawing it every frame cost ~10% of the decode limit.
    ./preview-opt-in.patch
    # --fisheye FOV: play side-by-side equidistant fisheye (e.g. 190°) by remapping in the shader, no re-encode.
    ./fisheye.patch
    # Controller playback controls on buttons WayVR leaves free (A/B, thumbsticks); see the usage text.
    ./controller-input.patch
  ];

  nativeBuildInputs = [
    cmake
    pkg-config
  ];

  buildInputs = [
    SDL2
    libGL
    libdrm
    wayland
    libepoxy
    glib
    pipewire
    mpv-unwrapped
    glm
    openxr-loader
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "OpenXR/Wayland VR video player, a fork of vr-video-player by dec05eba";
    homepage = "https://codeberg.org/yoshino/xr-video-player";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.linux;
    mainProgram = "xr-video-player";
  };
}
