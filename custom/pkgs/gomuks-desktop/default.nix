# gomuks ships its Electron desktop wrapper as a prebuilt .deb on GitHub
# Releases (only for tags that include desktop assets -- see update.sh) rather
# than as source you'd build with electron-forge yourself. The .deb already
# bundles a statically-linked copy of the same `gomuks` Go binary that
# gomuks-web ships, so this just extracts it and relinks the Electron shell's
# shared libraries with autoPatchelfHook.
{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  makeWrapper,
  alsa-lib,
  atk,
  at-spi2-atk,
  at-spi2-core,
  cairo,
  cups,
  dbus,
  expat,
  gdk-pixbuf,
  glib,
  gtk3,
  libdrm,
  libglvnd,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libXrandr,
  libxcb,
  libxkbcommon,
  mesa,
  nspr,
  nss,
  pango,
  udev,
}:

let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;

  # "26.06.0" -> "v0.2606.0", matching gomuks-web's tag scheme.
  parts = lib.splitString "." version;
  tag = "v0.${lib.elemAt parts 0}${lib.elemAt parts 1}.${lib.elemAt parts 2}";

  arch =
    {
      "x86_64-linux" = "amd64";
      "aarch64-linux" = "arm64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "gomuks-desktop";
  inherit version;

  src = fetchurl {
    url = "https://github.com/gomuks/gomuks/releases/download/${tag}/gomuks-desktop_${version}_${arch}.deb";
    hash = versions.hashes.${stdenv.hostPlatform.system};
  };

  passthru.runtimeLibraries = [
    alsa-lib
    atk
    at-spi2-atk
    at-spi2-core
    cairo
    cups
    dbus
    expat
    gdk-pixbuf
    glib
    gtk3
    libdrm
    libglvnd
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    udev
  ];

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    makeWrapper
  ];

  buildInputs = finalAttrs.passthru.runtimeLibraries;

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb --fsys-tarfile "$src" | tar --extract
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share/gomuks-desktop" "$out/bin"
    cp -r usr/lib/gomuks-desktop/. "$out/share/gomuks-desktop"

    install -Dm644 usr/share/applications/gomuks-desktop.desktop \
      "$out/share/applications/gomuks-desktop.desktop"
    install -Dm644 usr/share/pixmaps/gomuks-desktop.png \
      "$out/share/pixmaps/gomuks-desktop.png"

    # chrome-sandbox only works setuid-root, which the Nix store can't
    # provide; drop it and run with the sandbox disabled instead of wiring
    # up a NixOS security wrapper for a single optional hardening layer.
    rm -f "$out/share/gomuks-desktop/chrome-sandbox"

    # libEGL/libGLESv2 are dlopen'd by Chromium's ANGLE backend at runtime
    # rather than linked, so autoPatchelf's static RPATH never covers them;
    # without this they fail to resolve and rendering silently falls back to
    # software.
    makeWrapper "$out/share/gomuks-desktop/gomuks-desktop" "$out/bin/gomuks-desktop" \
      --add-flags "--no-sandbox" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.passthru.runtimeLibraries}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Electron desktop wrapper for the gomuks Matrix client";
    homepage = "https://github.com/gomuks/gomuks";
    license = lib.licenses.agpl3Only;
    mainProgram = "gomuks-desktop";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
