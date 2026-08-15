{
  lib,
  stdenv,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  wineWow64Packages,
  winetricks,
  dxvk,
  curl,
  cacert,
  pciutils,
  mesa-demos,
  mokutil,
  p7zip,
}:

stdenv.mkDerivation {
  pname = "fusion360";
  version = "unstable";

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
    copyDesktopItems
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ${./fusion360-launcher.sh} $out/bin/fusion360
    install -Dm755 ${./fusion360-idmgr-opener.sh} $out/bin/fusion360-idmgr-opener

    for prog in $out/bin/fusion360 $out/bin/fusion360-idmgr-opener; do
      wrapProgram "$prog" \
        --prefix PATH : ${
          lib.makeBinPath [
            wineWow64Packages.staging
            winetricks
            curl
            pciutils
            mesa-demos
            mokutil
            p7zip
          ]
        } \
        --set FUSION360_DXVK_X32 ${dxvk.bin}/x32 \
        --set FUSION360_DXVK_X64 ${dxvk.bin}/x64 \
        --set FUSION360_MACHINE_OPTIONS_XML_DXVK ${./NMachineSpecificOptions-dxvk.xml} \
        --set FUSION360_MACHINE_OPTIONS_XML_OPENGL ${./NMachineSpecificOptions-opengl.xml} \
        --set SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt
    done

    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "fusion360";
      desktopName = "Autodesk Fusion 360";
      genericName = "3D CAD/CAM design";
      comment = "Windows CAD/CAM application, run under Wine";
      exec = "fusion360";
      categories = [
        "Graphics"
        "Engineering"
      ];
      terminal = false;
    })
    (makeDesktopItem {
      name = "fusion360-idmgr-opener";
      desktopName = "Autodesk Identity Manager (Fusion 360 login helper)";
      comment = "Handles adskidmgr:// sign-in callbacks for Autodesk Fusion 360";
      exec = "fusion360-idmgr-opener %u";
      noDisplay = true;
      mimeTypes = [ "x-scheme-handler/adskidmgr" ];
      terminal = false;
    })
  ];

  meta = {
    description = "Launcher that installs and runs Autodesk Fusion 360 (Windows-only) under Wine, with DXVK or OpenGL chosen per GPU";
    homepage = "https://www.autodesk.com/products/fusion-360";
    license = lib.licenses.unfree;
    mainProgram = "fusion360";
    platforms = [ "x86_64-linux" ];
  };
}
