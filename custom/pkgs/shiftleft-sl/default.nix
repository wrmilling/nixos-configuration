{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  ...
}:

let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "x64";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
      };
      "x86_64-darwin" = {
        os = "osx";
        arch = "x64";
      };
      "aarch64-darwin" = {
        os = "osx";
        arch = "arm64";
      };
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "shiftleft-sl";
  inherit version;

  src = fetchurl {
    url = "https://cdn.shiftleft.io/download/sl-${version}-${plat.os}-${plat.arch}.tar.gz";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  nativeBuildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    tar -xzf "$src"
    install -Dm755 sl "$out/bin/sl"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "ShiftLeft CLI for code security analysis";
    homepage = "https://www.shiftleft.io";
    mainProgram = "sl";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
