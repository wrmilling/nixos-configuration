{
  lib,
  stdenvNoCC,
  fetchurl,
  autoPatchelfHook,
  ...
}:

let
  version = "0.9.4248";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "x64";
        sha256 = "sha256-1LS3pgT2jNFK3HE7fdwvXyI6hmxqxAoBEdiTm6U9sZ0=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-k5z3asQGHbgxK9cketQlCpYKXDdK6nXCzRHxrfOmuyQ=";
      };
      "x86_64-darwin" = {
        os = "osx";
        arch = "x64";
        sha256 = "sha256-4frEsX20CVmC6I7LHb7DFtI8vFC+phNI4bmtvddPdiY=";
      };
      "aarch64-darwin" = {
        os = "osx";
        arch = "arm64";
        sha256 = "sha256-1ipNQgIR/qK4YJRxokCkdWdjfnDYtOAIXhg/aMZ+hFc=";
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
