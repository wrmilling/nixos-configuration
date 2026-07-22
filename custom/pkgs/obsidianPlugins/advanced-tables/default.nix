# Obsidian community plugin, not packaged in nixpkgs. Ships as three loose
# release assets (no tarball), so this just fetches and places them.
{
  lib,
  stdenvNoCC,
  fetchurl,
}:
let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version;
in
stdenvNoCC.mkDerivation {
  pname = "advanced-tables-obsidian";
  inherit version;

  dontUnpack = true;

  manifest = fetchurl {
    url = "https://github.com/tgrosinger/advanced-tables-obsidian/releases/download/${version}/manifest.json";
    hash = versions.hashes.manifest;
  };
  main = fetchurl {
    url = "https://github.com/tgrosinger/advanced-tables-obsidian/releases/download/${version}/main.js";
    hash = versions.hashes.main;
  };
  styles = fetchurl {
    url = "https://github.com/tgrosinger/advanced-tables-obsidian/releases/download/${version}/styles.css";
    hash = versions.hashes.styles;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out
    cp $manifest $out/manifest.json
    cp $main $out/main.js
    cp $styles $out/styles.css

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Improved table navigation, formatting, manipulation, and formulas for Obsidian";
    homepage = "https://github.com/tgrosinger/advanced-tables-obsidian";
    changelog = "https://github.com/tgrosinger/advanced-tables-obsidian/releases/tag/${version}";
    license = lib.licenses.gpl3Only;
    platforms = lib.platforms.all;
  };
}
