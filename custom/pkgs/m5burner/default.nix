{
  lib,
  stdenv,
  fetchzip,
  autoPatchelfHook,
  makeWrapper,
  copyDesktopItems,
  makeDesktopItem,
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
  libglvnd,
  libdrm,
  libX11,
  libXcomposite,
  libXdamage,
  libXext,
  libXfixes,
  libxkbcommon,
  libXrandr,
  libxcb,
  mesa,
  nspr,
  nss,
  pango,
  python3,
  udev,
}: let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "m5burner";
  inherit version;

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
    libglvnd
    libdrm
    libxkbcommon
    mesa
    nspr
    nss
    pango
    stdenv.cc.cc.lib
    udev
    libX11
    libXcomposite
    libXdamage
    libXext
    libXfixes
    libXrandr
    libxcb
  ];

  src = fetchzip {
    url = "https://m5burner-cdn.m5stack.com/app/M5Burner-v3-beta-linux-x64.zip";
    hash = versions.hash;
    stripRoot = false;
    curlOptsList = [
      "--referer"
      "https://docs.m5stack.com/"
      "-A"
      "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/136.0 Safari/537.36"
    ];
  };

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeWrapper
  ];

  buildInputs = finalAttrs.passthru.runtimeLibraries;

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/m5burner $out/share/pixmaps
    cp -r ./* $out/share/m5burner/

    chmod +x \
      $out/share/m5burner/bin/m5burner \
      $out/share/m5burner/bin/chrome-sandbox \
      $out/share/m5burner/bin/chrome_crashpad_handler

    install -Dm644 \
      $out/share/m5burner/packages/view/assets/images/logo.png \
      $out/share/pixmaps/m5burner.png

    cat > $out/bin/m5burner <<EOF
    #!${stdenv.shell}
    set -eu

    src="$out/share/m5burner"
    stateRoot="''${XDG_STATE_HOME:-\$HOME/.local/state}/m5burner"
    runtimeRoot="\$stateRoot/app"
    stampFile="\$runtimeRoot/.nix-source"

    if [ ! -f "\$stampFile" ] || [ "\$(cat "\$stampFile")" != "\$src" ]; then
      rm -rf "\$runtimeRoot"
      mkdir -p "\$stateRoot"
      cp -r "\$src" "\$runtimeRoot"
      chmod -R u+w "\$runtimeRoot"
      printf '%s\n' "\$src" > "\$stampFile"
    fi

    mkdir -p \
      "\$runtimeRoot/packages/tmp" \
      "\$runtimeRoot/packages/dat" \
      "\$runtimeRoot/packages/share" \
      "\$runtimeRoot/packages/firmware"

    cd "\$runtimeRoot"
    exec ./bin/m5burner --disable-setuid-sandbox "\$@"
    EOF

    chmod +x $out/bin/m5burner
    wrapProgram $out/bin/m5burner \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath finalAttrs.passthru.runtimeLibraries} \
      --set LIBGL_DRIVERS_PATH ${mesa}/lib/dri \
      --prefix PATH : ${lib.makeBinPath [ python3 ]}

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  desktopItems = [
    (makeDesktopItem {
      name = finalAttrs.pname;
      desktopName = "M5Burner";
      exec = "m5burner %U";
      icon = "m5burner";
      categories = [
        "Development"
        "Utility"
      ];
      comment = "Firmware burning tool for M5Stack devices";
      startupWMClass = "m5burner";
    })
  ];

  meta = {
    description = "M5Stack firmware burning tool";
    homepage = "https://docs.m5stack.com/en/uiflow/m5burner/intro";
    license = lib.licenses.unfreeRedistributable;
    mainProgram = "m5burner";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = with lib.sourceTypes; [
      binaryNativeCode
    ];
  };
})
