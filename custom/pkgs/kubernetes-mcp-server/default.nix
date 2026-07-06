{
  lib,
  stdenvNoCC,
  fetchurl,
  ...
}:

let
  version = "0.0.63";
  plat =
    {
      "x86_64-linux" = {
        os = "linux";
        arch = "amd64";
        sha256 = "sha256-ysEVrf7CMJdpnwoiK+c72fE9L91fzsMuquy1oZLuT6Q=";
      };
      "aarch64-linux" = {
        os = "linux";
        arch = "arm64";
        sha256 = "sha256-1lgH+4m3sqM4chPBpybkz3LqP+JgeVHVuu0/rBDUYrY=";
      };
      "x86_64-darwin" = {
        os = "darwin";
        arch = "amd64";
        sha256 = "sha256-MYP6qzA2oxggp39KtwktM7/GyzZEXMCPyk0CTbxPzYM=";
      };
      "aarch64-darwin" = {
        os = "darwin";
        arch = "arm64";
        sha256 = "sha256-iosGUkRm/lpBeADgOG8lT3UOdIY4IH9Cm1jjYebcoz8=";
      };
    }
    .${stdenvNoCC.hostPlatform.system};
in
stdenvNoCC.mkDerivation {
  pname = "kubernetes-mcp-server";
  inherit version;

  src = fetchurl {
    url = "https://github.com/manusa/kubernetes-mcp-server/releases/download/v${version}/kubernetes-mcp-server-${plat.os}-${plat.arch}";
    sha256 = plat.sha256;
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
