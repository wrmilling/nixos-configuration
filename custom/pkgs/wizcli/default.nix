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
      "x86_64-linux" = {
        os = "linux";
        arch = "amd64";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
      };
      "x86_64-darwin" = {
        os = "darwin";
        arch = "amd64";
      };
      "aarch64-darwin" = {
        os = "darwin";
        arch = "arm64";
      };
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "wizcli";
  inherit version;

  src = fetchurl {
    url = "https://downloads.wiz.io/v${lib.versions.major version}/wizcli/${version}/wizcli-${plat.os}-${plat.arch}";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/wizcli"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "CLI for interacting with the Wiz platform";
    homepage = "https://www.wiz.io";
    license = lib.licenses.unfree;
    mainProgram = "wizcli";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
