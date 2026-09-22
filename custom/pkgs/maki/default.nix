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
      "x86_64-linux" = "x86_64-unknown-linux-musl";
      "aarch64-linux" = "aarch64-unknown-linux-musl";
      "x86_64-darwin" = "x86_64-apple-darwin";
      "aarch64-darwin" = "aarch64-apple-darwin";
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "maki";
  inherit version;

  src = fetchurl {
    url = "https://github.com/tontinton/maki/releases/download/v${version}/maki-v${version}-${plat}.tar.gz";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    tar -xzf "$src"
    install -Dm755 maki "$out/bin/maki"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Efficient AI coding agent extendable by neovim-like Lua plugins";
    homepage = "https://github.com/tontinton/maki";
    changelog = "https://github.com/tontinton/maki/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "maki";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
