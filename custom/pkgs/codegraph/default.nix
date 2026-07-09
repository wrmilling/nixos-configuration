# Based on the upstream nixpkgs derivation (pkgs/by-name/co/codegraph/package.nix,
# maintained by gdifolco). Kept here as a custom package so version bumps don't have
# to wait on nixpkgs channel promotion -- upstream releases fairly often and this
# repo wants to track it more closely. Bump `version` + `passthru.sources` hashes (or
# run the updateScript) to update; the build logic itself should stay in sync with
# nixpkgs' package.nix if it changes upstream.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  writeShellScript,
  curl,
  gnused,
  common-updater-scripts,
  cctools,
  darwin,
  rcodesign,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "codegraph";
  version = "1.3.1";

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
        hash = "sha256-1JMTNOJJekhhshTsB3145eOHAqJY/k4Fwz7TvB0USpA=";
      };
      "aarch64-linux" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-arm64.tar.gz";
        hash = "sha256-KBMNpvbHCH0pMzdzffyhBA8GlJlrAlLJUop3BqVyHYs=";
      };
      "x86_64-darwin" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-darwin-x64.tar.gz";
        hash = "sha256-6TZM+LEEzykMfJbvHtPc0w0Xr1ZYPN8Ake+gsAHjZp4=";
      };
      "x86_64-linux" = fetchurl {
        url = "https://github.com/colbymchenry/codegraph/releases/download/v${finalAttrs.version}/codegraph-linux-x64.tar.gz";
        hash = "sha256-5gUHP26xcP4WHphsI1C2oGgeaAGO2ETOV/coFMCf6h0=";
      };
    };
    updateScript = writeShellScript "update-codegraph" ''
      set -o errexit
      export PATH="${
        lib.makeBinPath [
          curl
          gnused
          common-updater-scripts
        ]
      }"
      NEW_VERSION=$(curl --silent -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/colbymchenry/codegraph/releases/latest" | sed -n 's#.*/releases/tag/v##p')
      if [[ "${finalAttrs.version}" = "$NEW_VERSION" ]]; then
          echo "The new version same as the old version."
          exit 0
      fi
      for platform in ${lib.escapeShellArgs finalAttrs.meta.platforms}; do
        update-source-version "codegraph" "$NEW_VERSION" --ignore-same-version --source-key="sources.$platform"
      done
    '';
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
