{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:

let
  version = "0.54.1";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "amd64";
        sha256 = "sha256-RnDaepoBnpNoIgWl++oqAqVwLO2AtMnVAbGrAKvrMoo=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-sQ7bVHNylIfXC0nnRWRvwVSikcr/z048rDxwxTGWtpU=";
      };
      "x86_64-darwin" = {
        os = "darwin";
        arch = "amd64";
        sha256 = "sha256-whVbRX0XHHKdL421lA/iyxZULAX/QmEgAsGcH62166c=";
      };
      "aarch64-darwin" = {
        os = "darwin";
        arch = "arm64";
        sha256 = "sha256-usu5hKdex8yYK/8y/afN3f6HW2uvrvarFNTNKeCUBqk=";
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
