{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  ...
}:

let
  version = "0.9.4265";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "x64";
        sha256 = "sha256-cCC/BhnPVkornSnAdNXjHeDyGBWCyT0l2wWaFneSQZo=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-jL8t6YJL6kCQ8OjOuHEaY9j8a4c9Twqp/oL3odW5MQ8=";
      };
      "x86_64-darwin" = {
        os = "osx";
        arch = "x64";
        sha256 = "sha256-NqEFKAKgBWH0R5gxLb+slFBi945fMEMhUNPVWt5kKeU=";
      };
      "aarch64-darwin" = {
        os = "osx";
        arch = "arm64";
        sha256 = "sha256-DK8Fwb2/IHQuWqBtuHhLXwWj2x3Pp+Pera7TM1eJsbY=";
      };
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "shiftleft-sl";
  inherit version;

  src = fetchurl {
    url = "https://cdn.shiftleft.io/download/sl-${version}-${plat.os}-${plat.arch}.tar.gz";
    sha256 = plat.sha256;
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
