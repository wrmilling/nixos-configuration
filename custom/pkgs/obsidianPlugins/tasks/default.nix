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
  pname = "obsidian-tasks";
  inherit version;

  dontUnpack = true;

  manifest = fetchurl {
    url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/${version}/manifest.json";
    hash = versions.hashes.manifest;
  };
  main = fetchurl {
    url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/${version}/main.js";
    hash = versions.hashes.main;
  };
  styles = fetchurl {
    url = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/download/${version}/styles.css";
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
    description = "Track tasks across an Obsidian vault, with due dates, recurrence, and filtering";
    homepage = "https://github.com/obsidian-tasks-group/obsidian-tasks";
    changelog = "https://github.com/obsidian-tasks-group/obsidian-tasks/releases/tag/${version}";
    license = lib.licenses.mit;
    platforms = lib.platforms.all;
  };
}
