{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:

let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
  plat =
    {
      "x86_64-linux" = "linux-x86_64";
      "aarch64-linux" = "linux-aarch64";
      "x86_64-darwin" = "macos-x86_64";
      "aarch64-darwin" = "macos-aarch64";
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "herdr-core";
  inherit version;

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${version}/herdr-core-${plat}.tar.gz";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  sourceRoot = ".";

  dontConfigure = true;
  dontBuild = true;

  # The Linux builds are static musl, so nothing needs patching.
  installPhase = ''
    install -Dm755 herdr-core "$out/bin/herdr-core"
    ln -s herdr-core "$out/bin/hc"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Server and CLI (hc) behind the Herdr desktop app for running coding agents";
    homepage = "https://herdr.dev/core/";
    license = lib.licenses.asl20;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    mainProgram = "hc";
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  };
}
