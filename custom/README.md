# Custom Packages

Definition of custom packages which are generally not yet available in upstream nixpkgs or deired to have faster version bumps than upstream can support.

## Current Packages

- [cc9s](pkgs/cc9s) — Kubernetes TUI client (kincoy/cc9s).
- [slides-git](pkgs/slides-git) — Terminal based presentation tool (upstream build from git).
- [kubernetes-mcp-server](pkgs/kubernetes-mcp-server) — MCP server for Kubernetes cluster interaction.
- [flux-operator-mcp](pkgs/flux-operator-mcp) — MCP server for FluxCD GitOps cluster management.
- [gomuks-desktop](pkgs/gomuks-desktop) — Electron wrapper for gomuks (Matrix client), built from upstream's prebuilt .deb.
- [codegraph](pkgs/codegraph) — Local code knowledge graph MCP server for AI coding agents (tracked ahead of the nixpkgs-provided version).
- [shiftleft-sl](pkgs/shiftleft-sl) — ShiftLeft CLI for code security analysis.
- [m5burner](pkgs/m5burner) — M5Stack firmware burning tool.
- [maki](pkgs/maki) — AI coding agent extendable by neovim-like Lua plugins (tontinton/maki).
- [xr-video-player](pkgs/xr-video-player) — OpenXR/Wayland VR video player, built from git (no upstream releases yet).
- [fusion360](pkgs/fusion360) — Launcher that sets up a Wine/DXVK prefix and installs Autodesk Fusion 360 (proprietary, Windows-only) from Autodesk's own installer on first run; no upstream binary is fetched or pinned by Nix.
- [obsidianPlugins](pkgs/obsidianPlugins) — Obsidian community plugins, namespaced under `pkgs.obsidianPlugins.<name>` since none are packaged in nixpkgs:
  - `pandoc` — Export notes via Pandoc (DOCX, ePub, PDF, ...).
  - `dataview` — Data index and query language over Markdown notes.
  - `advanced-tables` — Improved table navigation, formatting, and manipulation.
  - `tasks` — Track tasks across a vault, with due dates, recurrence, and filtering.
  - `tasknotes` — Note-based task management with calendar, kanban, pomodoro, and time-tracking integration.

## Updating packages

```sh
custom/pkgs/update.sh                        # update every package
custom/pkgs/update.sh <name>                 # update one, e.g. codegraph, slides-git, m5burner
custom/pkgs/update.sh obsidianPlugins/<name> # update one plugin under a namespace, e.g. obsidianPlugins/dataview
```

Prints what it did (or "already up to date") per package; review the diff and
build (`nix build .#packages.<system>.<name>`, e.g. `.#obsidianPlugins.dataview`) before committing.

## Overlays

The `custom/overlays` directory provides Nix overlays that are applied to the flake inputs. Current overlays in `custom/overlays/default.nix`:

- `additions` — Adds the repository's custom packages from `custom/pkgs` into the final package set (`pkgs`).
- `claude-code` — Exposes `pkgs.claude-code` from the `claude-code-nix` flake input. Kept separate from `additions` so it can be selectively applied to home-manager configs without touching NixOS hosts.
- `claude-desktop` — Exposes `pkgs.claude-desktop` from the `nixpkgs-claude-desktop` flake input (allowUnfree).
- `fast-resume` — Exposes `pkgs.fast-resume` from the `fast-resume` flake's own `packages.<system>.default` (no overlays output upstream).
- `modifications` — Patches and overrides existing packages:
  - `openldap` — disable its test suite on i686.
  - `rancher` — disable its Go test suite (it tries to bind a TCP listener).
  - `linuxPackagesFor` — bump `linuxPackages.facetimehd` to 0.7.0.1 (nixpkgs PR #510918).
- `stable-packages` — Makes a stable `nixpkgs` set available as `pkgs.stable` (configured with `allowUnfree = true`).
- `unstable-small-packages` — Makes the `nixpkgs-unstable-small` set available as `pkgs.unstable-small` (configured with `allowUnfree = true`).