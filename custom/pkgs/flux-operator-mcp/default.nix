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
  pname = "flux-operator-mcp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${version}/flux-operator-mcp_${version}_${plat.os}_${plat.arch}.tar.gz";
    sha256 = versions.hashes.${stdenvNoCC.hostPlatform.system};
  };

  dontConfigure = true;
  dontBuild = true;

  unpackPhase = ''
    tar xzf "$src"
  '';

  installPhase = ''
    install -Dm755 flux-operator-mcp "$out/bin/flux-operator-mcp"
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "MCP server for FluxCD GitOps cluster management";
    homepage = "https://github.com/controlplaneio-fluxcd/flux-operator";
    mainProgram = "flux-operator-mcp";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
