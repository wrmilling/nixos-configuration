{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  libGL,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
}:

let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
  plat =
    {
      "x86_64-linux" = "linux-x86_64";
      "aarch64-linux" = "linux-aarch64";
    }
    .${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${version}/herdr-app-${plat}.tar.gz";
    sha256 = versions.hashes.${stdenv.hostPlatform.system};
  };

  # GPUI dlopens Vulkan, Wayland and EGL rather than linking them.
  passthru.runtimeLibraries = [
    libGL
    vulkan-loader
    wayland
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    libxcb
    libxkbcommon
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  # The icon stays out of the binary's folder: the app only self-updates when
  # herdr-app.svg sits beside it, which would fail inside the Nix store.
  installPhase = ''
    runHook preInstall

    install -Dm755 herdr-app "$out/libexec/herdr-app/herdr-app"
    install -Dm644 herdr-app.svg "$out/share/icons/hicolor/scalable/apps/herdr-app.svg"
    makeWrapper "$out/libexec/herdr-app/herdr-app" "$out/bin/herdr-app" \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.passthru.runtimeLibraries}

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      categories = [ "Development" ];
      startupWMClass = "herdr-app";
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Desktop app for running terminals and coding agents on herdr-core";
    homepage = "https://herdr.dev/";
    changelog = "https://github.com/herdrdev/herdr-app/blob/master/CHANGELOG.md";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "herdr-app";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
  };
})
