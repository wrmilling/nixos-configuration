# Custom Packages

Definition of custom packages which are generally not yet available in upstream nixpkgs or deired to have faster version bumps than upstream can support.

## Current Packages

- [slides-git](pkgs/slides-git) — Terminal based presentation tool (upstream build from git).
- [mcpelauncher-client-git](pkgs/mcpelauncher-client) — Unofficial Minecraft Bedrock Edition launcher with CLI (built from git/tag).
- [mcpelauncher-ui-qt-git](pkgs/mcpelauncher-ui-qt) — Unofficial Minecraft Bedrock Edition launcher with GUI (Qt frontend).
- [kubernetes-mcp-server](pkgs/kubernetes-mcp-server) — MCP server for Kubernetes cluster interaction.
- [flux-operator-mcp](pkgs/flux-operator-mcp) — MCP server for FluxCD GitOps cluster management.
- [codegraph](pkgs/codegraph) — Local code knowledge graph MCP server for AI coding agents (tracked ahead of the nixpkgs-provided version).
- [shiftleft-sl](pkgs/shiftleft-sl) — ShiftLeft CLI for code security analysis.
- [m5burner](pkgs/m5burner) — M5Stack firmware burning tool.
- [appflowy](pkgs/appflowy) — Open-source Notion alternative (tracked ahead of the nixpkgs-provided version).
- [obsidianPlugins](pkgs/obsidianPlugins) — Obsidian community plugins, namespaced under `pkgs.obsidianPlugins.<name>` since none are packaged in nixpkgs:
  - `base-board` — Property-driven Kanban board view powered by Bases.
  - `pandoc` — Export notes via Pandoc (DOCX, ePub, PDF, ...).
  - `dataview` — Data index and query language over Markdown notes.
  - `advanced-tables` — Improved table navigation, formatting, and manipulation.

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
- `modifications` — Provides a place to modify or override existing packages (examples are included).
  - `opencode` — An overlay provided from the `opencode-git` flake input; exposes the `opencode` package set used for the Codex/Opencode agent tooling. Upstream repository: https://github.com/anomalyco/opencode
- `stable-packages` — Makes a stable `nixpkgs` set available as `pkgs.stable` (configured with `allowUnfree = true`).