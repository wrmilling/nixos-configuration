{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  ...
}:

let
  version = "0.9.4243";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "x64";
        sha256 = "sha256-yKAcCutt+OVY0Ryyd8LiV2TTF4XvYSzeMXRQFeAcQ7A=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-iO47wGgVapmj66XrOczCbNBn3YbklPWOCOXENBySr0E=";
      };
      "x86_64-darwin" = {
        os = "osx";
        arch = "x64";
        sha256 = "sha256-pmox9DGKWowHcyXllT7k1PjNp5J35tgJo6eZk7GgG1w=";
      };
      "aarch64-darwin" = {
        os = "osx";
        arch = "arm64";
        sha256 = "sha256-lIyolc7xR16Ar0zzQaL8y+vfUbeZx4k6ycT4n5iwuIM=";
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
