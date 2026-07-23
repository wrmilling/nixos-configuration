---
name: custom-packaging
description: Use when adding, updating, or porting a package under custom/pkgs in this repo — including Obsidian community plugins under pkgs.obsidianPlugins. Covers directory layout, versions.json/update.sh conventions, which fetcher/hash pattern fits an upstream, and registration/documentation steps.
---

# Custom package packaging

Conventions for packages under `custom/pkgs/` in this flake — both general
applications/CLIs and Obsidian community plugins (`pkgs.obsidianPlugins.<name>`).

## Before writing anything

Search nixpkgs first, including the revision pinned in `flake.lock` (a
package can exist upstream even if it's not in whatever channel you're
picturing) — use the `mcp-nixos` MCP tools rather than guessing. Only write
a custom package if it's genuinely missing, or you deliberately want faster
version bumps than nixpkgs channel promotion gives you (see `codegraph`).
If you're porting an existing nixpkgs derivation for that
reason, base it on the upstream `package.nix` and leave a comment noting
where it came from and that build logic should stay in sync if upstream
changes it — see `custom/pkgs/codegraph/default.nix` for the pattern.

## Layout

```
custom/pkgs/<name>/
  default.nix   # takes standard nixpkgs args + `lib.importJSON ./versions.json`
  versions.json # version + hash(es) — never hardcode these in default.nix
  update.sh     # executable; re-run to bump version.json
  *.patch       # only if the build needs source patches (see mcpelauncher-client)
```

Obsidian plugins live one level deeper, under a namespace directory:

```
custom/pkgs/obsidianPlugins/<name>/{default.nix,versions.json,update.sh}
custom/pkgs/obsidianPlugins/default.nix   # { pkgs }: { <name> = pkgs.callPackage ./<name> { }; ... }
```

This namespace pattern generalizes to any future grouped set, not just
Obsidian plugins — `custom/pkgs/update.sh` discovers one level of nesting
automatically by looking for `versions.json` inside each subdirectory, so a
new namespace needs no changes to the update driver itself.

## Registration

- Flat package: add `<name> = pkgs.callPackage ./<name> { };` to the `rec {
  ... }` set in `custom/pkgs/default.nix`.
- New package in an existing namespace (e.g. another Obsidian plugin): add
  it to that namespace's own `default.nix` (e.g.
  `custom/pkgs/obsidianPlugins/default.nix`) — the top-level
  `custom/pkgs/default.nix` already wires the whole namespace in via
  `<namespace> = import ./<namespace> { inherit pkgs; };` and needs no
  further changes.
- New namespace: create `custom/pkgs/<namespace>/default.nix` following the
  `{ pkgs }: { <name> = pkgs.callPackage ./<name> { }; ... }` shape, then add
  one line for it to the top-level `custom/pkgs/default.nix`.
- Document every package (or namespace + its members) in
  `custom/README.md`'s "Current Packages" list, one line of description each.

## `versions.json` conventions

Always `lib.importJSON ./versions.json` in `default.nix`, never hardcode a
version or hash inline. Shape depends on what's being fetched:

- Single file/platform: `{ "version": "...", "hash": "sha256-..." }` (or
  `"sha256"` — match whichever the fetcher function's argument is named).
- Multiple files (e.g. an Obsidian plugin's loose release assets):
  `{ "version": "...", "hashes": { "manifest": "...", "main": "...", "styles": "..." } }`.
- Multiple platforms: `{ "version": "...", "hashes": { "x86_64-linux": "...", "aarch64-darwin": "...", ... } }`.
- Built from source (`buildGoModule` + `fetchFromGitHub`): also carries
  `"rev"` and `"vendorHash"`.

## `default.nix` archetypes

Pick based on what the upstream project actually publishes. Use an existing
package as your literal starting point — copy it, don't write from scratch.

**Loose release assets, no tarball** (all current Obsidian plugins: `manifest.json`/`main.js`/`styles.css`
fetched individually) — canonical example: `custom/pkgs/obsidianPlugins/dataview/default.nix`.
`stdenvNoCC.mkDerivation`, `dontUnpack = true`, one `fetchurl` per asset,
`installPhase` just copies each into `$out`. `meta.changelog` points at
`.../releases/tag/${version}`.

**Prebuilt binary per platform** (single executable or tarball, no GUI
chrome) — canonical examples: `custom/pkgs/kubernetes-mcp-server`,
`custom/pkgs/flux-operator-mcp`, `custom/pkgs/shiftleft-sl`. A `plat`
let-binding maps `stdenv.hostPlatform.system` → the upstream's own
os/arch naming, `fetchurl` (`sha256 = versions.hashes.${stdenv.hostPlatform.system}`),
`autoPatchelfHook` if it's a native binary needing dynamic libs patched,
`installPhase` installs straight to `$out/bin`.

**`fetchzip`-based GUI app** (Electron/Chromium-style apps shipped as a zip
or `.deb`, need desktop integration) — canonical examples:
`custom/pkgs/m5burner`, `custom/pkgs/gomuks-desktop`.
`stdenv.mkDerivation (finalAttrs: { ... })`, `passthru.runtimeLibraries` +
`wrapProgram`/`makeWrapper` with `LD_LIBRARY_PATH`, `makeDesktopItem`. The
hash is of the *unpacked* tree — see the hash-fetching section below, this
can't use `nix store prefetch-file` directly.

**Built from source** (`buildGoModule` + `fetchFromGitHub`) — canonical
examples: `custom/pkgs/slides-git`, `custom/pkgs/cc9s`. `versions.json`
carries `version`, `rev`, and `vendorHash`.

Every archetype ends with `passthru.updateScript = ./update.sh;` and a
`meta` block (`description`, `homepage`, `changelog` when there's a
releases page, `license`, `platforms` or `mainProgram`, plus
`sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];` for
anything shipped as a prebuilt binary blob).

## `update.sh` conventions

Every `update.sh` is a standalone executable script (`#!/usr/bin/env bash`,
`set -euo pipefail`) invoked either directly or via
`custom/pkgs/update.sh [<name>|<namespace>/<name>]`. Never assume `jq` (or
any other utility) is on `PATH` — always shell out via `nix shell
nixpkgs#jq -c jq ...`, matching the rest of the repo's convention for
one-off utilities.

1. Resolve paths from `BASH_SOURCE`, read the current version:
   `nix shell nixpkgs#jq -c jq -r '.version' "$versions_file"`.
2. Discover the latest upstream version. Default to the GitHub releases API's
   `/latest` endpoint, which by definition excludes drafts and prereleases
   and uses authenticated `gh` (avoiding unauthenticated GitHub rate limits)
   — this is what most packages in the repo already do (`cc9s`,
   `kubernetes-mcp-server`, `flux-operator-mcp`, `codegraph`):
   ```sh
   new_version=$(gh api repos/<owner>/<repo>/releases/latest --jq .tag_name | sed 's/^v//')
   ```
   (Drop the `sed` if the upstream's tags have no `v` prefix — check what
   the existing `${version}` interpolation in `default.nix`'s download URL
   expects.) Fall back to something else only when `/latest` isn't the right
   query:
   - No GitHub releases API at all (a non-GitHub CDN, or a repo that only
     tags without publishing Releases) — run the fetched binary's
     `--version` (`custom/pkgs/shiftleft-sl/update.sh`), or query the tags
     API instead (`custom/pkgs/mcpelauncher-client/update.sh`).
   - The single latest release isn't guaranteed to have what you need (e.g.
     not every tag ships the asset this package cares about) — list and scan
     recent releases instead of trusting `/latest`
     (`custom/pkgs/gomuks-desktop/update.sh`).
   - The package intentionally tracks upstream's default branch past its
     last tag rather than "latest release" (documented, with the reasoning,
     in `custom/pkgs/slides-git/update.sh`) — use the branch/commit API
     instead.
3. Bail out early if unchanged: `echo "<name> already up to date at
   $current_version"; exit 0`.
4. Resolve the new hash(es) — the method depends on the fetcher:
   - Flat file (`fetchurl`): `nix --extra-experimental-features nix-command
     store prefetch-file --hash-type sha256 --json <url> | nix shell
     nixpkgs#jq -c jq -r .hash`.
   - Unpacked tree (`fetchzip`): `nix store prefetch-file` doesn't apply.
     Write a placeholder hash into `versions.json`, `nix build --impure`
     the package, and read the real hash out of the mismatch error (`sed -n
     's/^ *got: *//p'`) — see `custom/pkgs/m5burner/update.sh` for the full
     `resolve_hash()` function to copy. Watch for unfree licenses needing
     `NIXPKGS_ALLOW_UNFREE=1` on that build.
   - Multiple files or platforms: loop over a small table (asset-key/URL
     pairs, or system/os/arch triples) building up a `hashes_json` object
     via repeated `jq '.[$key] = $hash'`, then merge it into
     `versions.json` in one final `jq` call — see
     `custom/pkgs/obsidianPlugins/dataview/update.sh` or
     `custom/pkgs/shiftleft-sl/update.sh`.
5. Write back through a `$versions_file.tmp` + `mv`, never edit in place
   with `jq -i` (jq has no in-place flag).
6. Finish with `echo "Updated <name> $old -> $new"`.
7. Wire it up with `passthru.updateScript = ./update.sh;` in `default.nix`
   so `custom/pkgs/update.sh <name>` finds it. (A ported-from-nixpkgs
   package like `codegraph` can instead expose `passthru.updateScript` as a
   real derivation the way upstream nixpkgs does — the generic driver
   handles both: it runs a script directly if `update.sh` is executable,
   otherwise it builds `passthru.updateScript` and runs the result.)

## Obsidian plugins specifically

- Before writing `default.nix`, fetch the plugin's `manifest.json` off its
  GitHub release (or repo) and note its `id` field — that's the runtime
  install-folder name and the entry Obsidian writes into
  `community-plugins.json`, and it is frequently **not** the same as
  whatever Nix `pname` you'd naturally pick. Example:
  `advanced-tables-obsidian`'s manifest `id` is `table-editor-obsidian`; the
  built `community-plugins.json` array must use the `id`, and
  `programs.obsidian`'s plugin loader keys off the derivation's `manifest.json`
  content, not the attribute name — so this only matters for your own
  mental model, not something you need to hardcode anywhere.
- Fetch exactly the loose assets the release actually publishes — normally
  `manifest.json`, `main.js`, `styles.css`, but not every plugin ships a
  `styles.css`; drop that `fetchurl`/`cp` pair for a plugin that doesn't
  publish one rather than fetching a 404.
- After packaging, add it to `defaultSettings.communityPlugins` in
  `modules/home/components/graphical.obsidian.nix`:
  `{ pkg = pkgs.obsidianPlugins.<name>; }`.

## Verifying

```sh
nix build .#packages.<system>.<name>                       # flat package
nix build .#packages.<system>.obsidianPlugins.<name>        # namespaced package
```

For an Obsidian plugin, also rebuild the affected home configuration and
check the generated vault output:

```sh
nix build .#homeConfigurations."w4cbe@<host>".activationPackage --no-link --print-out-paths
# then, from the printed path:
cat $(readlink -f <out>/home-files)/.obsidian/<vault>/.obsidian/community-plugins.json
ls $(readlink -f <out>/home-files)/.obsidian/<vault>/.obsidian/plugins/<manifest-id>/
```

## Updating an existing package

```sh
custom/pkgs/update.sh                        # every package
custom/pkgs/update.sh <name>                  # one flat package
custom/pkgs/update.sh obsidianPlugins/<name>  # one namespaced package
custom/pkgs/update.sh --list                  # print discovered package names, update nothing
```

**Never run the bare no-arg form just to test a change to `update.sh`
itself** — it updates every real package in the repo, which is almost
certainly not what you want mid-task. Target a specific package instead.
Review the `versions.json` diff and `nix build` the package before
committing.

`--list` is what `.forgejo/workflows/update-packages.yml`'s `discover` job
reads its matrix from — it's the one place that knows how to expand a
namespace directory into its members and skip delegation wrappers. If you
ever touch package discovery, change it here and nowhere else; a CI step
that reimplements this listing instead of calling `--list` will silently
drift out of sync with new namespaces (this happened once already, when
`obsidianPlugins` was added: CI's own copy of the loop didn't know to
descend into it and tried to update the namespace directory itself).
