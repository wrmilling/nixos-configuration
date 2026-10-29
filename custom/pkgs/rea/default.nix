{
  lib,
  stdenv,
  buildNpmPackage,
  fetchurl,
  fetchFromGitHub,
  nodejs_24,
  python3,
  unicorn,
}:
let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;

  # The npm tarball ships the compiled dist/ but no lockfile; the repo's lockfile at the release tag matches it.
  lockfile = fetchurl {
    url = "https://raw.githubusercontent.com/morluto/rea/rea-agents-${version}/package-lock.json";
    hash = versions.hashes.lockfile;
  };

  # frida's install script downloads its prebuilt N-API binding at build time; fetch it here instead.
  fridaBinding =
    let
      plat =
        {
          x86_64-linux = "linux-x64";
          aarch64-linux = "linux-arm64";
          x86_64-darwin = "darwin-x64";
          aarch64-darwin = "darwin-arm64";
        }
        .${stdenv.hostPlatform.system};
    in
    fetchurl {
      url = "https://github.com/frida/frida/releases/download/${versions.frida.version}/frida-v${versions.frida.version}-napi-v8-${plat}.tar.gz";
      hash = versions.frida.hashes.${stdenv.hostPlatform.system};
    };

  # rea's ELF and core bridges refuse any pyelftools/unicorn other than the exact versions they audited.
  unicornPinned = unicorn.overrideAttrs {
    inherit (versions.pwntools.unicorn) version;
    src = fetchFromGitHub {
      owner = "unicorn-engine";
      repo = "unicorn";
      tag = versions.pwntools.unicorn.version;
      inherit (versions.pwntools.unicorn) hash;
    };
  };

  pwntoolsPython = python3.override {
    self = pwntoolsPython;
    packageOverrides = _: prev: {
      unicorn = (prev.unicorn.override { unicorn = unicornPinned; }).overridePythonAttrs {
        # versioningit derives the version from git tags, which the GitHub tarball lacks.
        postPatch = ''
          substituteInPlace pyproject.toml \
            --replace-fail 'dynamic = ["version"]' 'version = "${unicornPinned.version}"' \
            --replace-fail ', "versioningit"' "" \
            --replace-fail '[tool.versioningit]' ""
        '';
      };
      pyelftools = prev.pyelftools.overridePythonAttrs {
        inherit (versions.pwntools.pyelftools) version;
        src = fetchFromGitHub {
          owner = "eliben";
          repo = "pyelftools";
          tag = "v${versions.pwntools.pyelftools.version}";
          inherit (versions.pwntools.pyelftools) hash;
        };
      };
    };
  };
in
buildNpmPackage {
  pname = "rea";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/rea-agents/-/rea-agents-${version}.tgz";
    hash = versions.hashes.src;
  };

  nodejs = nodejs_24;
  inherit (versions) npmDepsHash;

  postPatch = ''
    cp ${lockfile} package-lock.json
  '';

  npmRebuildFlags = [ "--ignore-scripts" ];
  postConfigure = ''
    tar -xzf ${fridaBinding} -C node_modules/frida
  '';

  dontNpmBuild = true;
  env.HUSKY = "0";

  passthru = {
    updateScript = ./update.sh;

    # External engines rea expects the caller to supply, at the versions this release pins.
    pwntoolsPython = pwntoolsPython.withPackages (ps: [ ps.pwntools ]);
    jadxMcpJar = fetchurl {
      url = "https://github.com/1013503897/jadx-headless-mcp/releases/download/v${versions.jadxMcp.version}/jadx-headless-mcp-${versions.jadxMcp.version}-all.jar";
      inherit (versions.jadxMcp) hash;
    };
  };

  meta = {
    description = "Reverse-engineering MCP server and CLI for coding agents";
    homepage = "https://github.com/morluto/rea";
    changelog = "https://github.com/morluto/rea/releases/tag/rea-agents-${version}";
    license = lib.licenses.mit;
    mainProgram = "rea";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
