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
  pname = "kubernetes-mcp-server";
  inherit version;

  src = fetchurl {
    url = "https://github.com/manusa/kubernetes-mcp-server/releases/download/v${version}/kubernetes-mcp-server-${plat.os}-${plat.arch}";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    install -Dm755 "$src" "$out/bin/kubernetes-mcp-server"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "MCP server for Kubernetes cluster interaction";
    homepage = "https://github.com/manusa/kubernetes-mcp-server";
    mainProgram = "kubernetes-mcp-server";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
