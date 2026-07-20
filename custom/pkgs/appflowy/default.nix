# Ported from nixpkgs (pkgs/by-name/ap/appflowy/package.nix), tracked here
# for faster version bumps than upstream nixpkgs currently provides.
{
  lib,
  stdenvNoCC,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
  gtk3,
  xdg-user-dirs,
  keybinder3,
  libnotify,
  gst_all_1,
  libva,
  libvdpau,
  lcms2,
  libarchive,
  alsa-lib,
  libpulseaudio,
  libgbm,
  libxscrnsaver,
  libxv,
  libgcrypt,
  libgpg-error,
  vulkan-loader,
  lz4,
  libxxf86vm,
  libglvnd,
}:

let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "appflowy";
  inherit version;

  src = fetchzip {
    url = "https://github.com/AppFlowy-IO/appflowy/releases/download/${finalAttrs.version}/AppFlowy-${finalAttrs.version}-linux-x86_64.tar.gz";
    hash = versions.hashes.x86_64-linux;
    stripRoot = false;
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    gtk3
    keybinder3
    libnotify
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    libva
    libvdpau
    lcms2
    libarchive
    alsa-lib
    libpulseaudio
    libgbm
    libxscrnsaver
    libxv
    libgcrypt
    libgpg-error
    vulkan-loader
    lz4
    libxxf86vm
    libglvnd
  ];

  dontBuild = true;
  dontConfigure = true;

  installPhase = ''
    runHook preInstall

    cd AppFlowy/

    mkdir -p $out/{bin,opt}

    cp -r ./* $out/opt/

    install -Dm444 data/flutter_assets/assets/images/flowy_logo.svg $out/share/icons/hicolor/scalable/apps/appflowy.svg

    runHook postInstall
  '';

  preFixup = ''
    # Add missing libraries to appflowy using the ones it comes with, plus
    # libglvnd: the Flutter engine dlopen()s libGLESv2.so.2 at runtime rather
    # than linking it, so autoPatchelf's static RPATH scan never covers it --
    # without this on the LD_LIBRARY_PATH, GL context creation aborts.
    makeWrapper $out/opt/AppFlowy $out/bin/appflowy \
      --set LD_LIBRARY_PATH "$out/opt/lib:${lib.makeLibraryPath [ libglvnd ]}" \
      --prefix PATH : "${lib.makeBinPath [ xdg-user-dirs ]}"
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "appflowy";
      desktopName = "AppFlowy";
      comment = finalAttrs.meta.description;
      exec = "appflowy %U";
      icon = "appflowy";
      categories = [ "Office" ];
      mimeTypes = [ "x-scheme-handler/appflowy-flutter" ];
    })
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Open-source alternative to Notion";
    homepage = "https://www.appflowy.io/";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = with lib.licenses; [
      # The LICENSE file claims AGPL-3.0, but the source hasn't been synced
      # with a release since late 2025 -- upstream says the Flutter code will
      # be merged back "at a later stage" -- so the shipped binary is
      # effectively unfree until that catches up.
      # c.f. https://github.com/AppFlowy-IO/AppFlowy/issues/8479#issuecomment-4053301446
      agpl3Only
      unfreeRedistributable
    ];
    changelog = "https://github.com/AppFlowy-IO/appflowy/releases/tag/${finalAttrs.version}";
    mainProgram = "appflowy";
    platforms = [ "x86_64-linux" ];
  };
})
