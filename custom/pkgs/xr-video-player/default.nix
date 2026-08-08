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

  # Upstream never reports real vsyncs to mpv, so its frame pacing can't
  # calibrate to the XR compositor's actual cadence, causing missed frames.
  patches = [ ./report-swap-sync.patch ];

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
