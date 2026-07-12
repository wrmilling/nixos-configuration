# Based on the upstream nixpkgs derivation (pkgs/by-name/co/codegraph/package.nix,
# maintained by gdifolco). Kept here as a custom package so version bumps don't have
# to wait on nixpkgs channel promotion -- upstream releases fairly often and this
# repo wants to track it more closely. Run ./update.sh to update; the build logic
# itself should stay in sync with nixpkgs' package.nix if it changes upstream.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  cctools,
  darwin,
  rcodesign,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codegraph";
  version = "1.4.1";

  src =
    finalAttrs.passthru.sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  sourceRoot =
    {
      "aarch64-darwin" = "codegraph-darwin-arm64";
      "aarch64-linux" = "codegraph-linux-arm64";
      "x86_64-darwin" = "codegraph-darwin-x64";
      "x86_64-linux" = "codegraph-linux-x64";
    }
    .${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  strictDeps = true;
  __structuredAttrs = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    autoPatchelfHook
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    cctools
    rcodesign
  ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/codegraph
    cp -r lib $out/lib/codegraph/lib
    cp node $out/lib/codegraph/node

    install -Dm 755 bin/codegraph $out/lib/codegraph/bin/codegraph

    mkdir -p $out/bin
    makeWrapper $out/lib/codegraph/bin/codegraph $out/bin/codegraph

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenv.hostPlatform.isDarwin ''
    '${lib.getExe' cctools "${cctools.targetPrefix}install_name_tool"}' $out/lib/codegraph/node \
      -change /usr/lib/libicucore.A.dylib '${lib.getLib darwin.ICU}/lib/libicucore.A.dylib'
    '${lib.getExe rcodesign}' sign --code-signature-flags linker-signed $out/lib/codegraph/node
  '';

  passthru = {
    sources = {
      "aarch64-darwin" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-darwin-arm64.tar.gz";
        hash = "sha256-Smea5aXLn/+QDdWbt4baalgbf2j0z3E73t0TfjR9NNw=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-arm64.tar.gz";
        hash = "sha256-DWLF6yci+NGdIPehvZdEReGNUpTLWb4Ragw9Vc6HWR8=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-darwin-x64.tar.gz";
        hash = "sha256-Q2+WlDz9km6m0KhFTxiDPSElTV/Zs9IkMXsUJhMt75U=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-x64.tar.gz";
        hash = "sha256-+1hf9QGNb6qkbSgrYfT2ibx5Z+2KG0Z6XFVt187ZtUI=";
      };
    };
  };

  meta = {
    description = "Pre-indexed code knowledge graph for AI coding agents";
    homepage = "https://github.com/colbymchenry/codegraph";
    changelog = "https://github.com/colbymchenry/codegraph/releases/tag/v${finalAttrs.version}";
    license = lib.licenses.mit;
    mainProgram = "codegraph";
    platforms = builtins.attrNames finalAttrs.passthru.sources;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
