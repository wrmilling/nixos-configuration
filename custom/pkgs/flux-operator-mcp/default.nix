{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:

let
  version = "0.53.0";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "amd64";
        sha256 = "sha256-td0Er9knMPsUj/yr8otgWKTq0chuXgMdHIrXWRRstHs=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-V18rvR70RwO0Ttt28+5uQfJ1YvzFXMQeMPO6pH29Ta8=";
      };
      "x86_64-darwin" = {
        os = "darwin";
        arch = "amd64";
        sha256 = "sha256-M8XgtPVO/pbinUwoaIpQSwdtEWFXqQ4BdQOA6UA+5e8=";
      };
      "aarch64-darwin" = {
        os = "darwin";
        arch = "arm64";
        sha256 = "sha256-2nZTlEYA6GBDk++BkPzdBB9WdfBxLzD7SZNbXp5nx00=";
      };
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "flux-operator-mcp";
  inherit version;

  src = fetchurl {
    url = "https://github.com/controlplaneio-fluxcd/flux-operator/releases/download/v${version}/flux-operator-mcp_${version}_${plat.os}_${plat.arch}.tar.gz";
    sha256 = plat.sha256;
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
