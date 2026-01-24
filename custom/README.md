# Custom Packages

Definition of custom packages which are generally not yet available in upstream nixpkgs.

## Current Packages

- [slides-git](pkgs/slides-git) — Terminal based presentation tool (upstream build from git).
- [mcpelauncher-client-git](pkgs/mcpelauncher-client) — Unofficial Minecraft Bedrock Edition launcher with CLI (built from git/tag).
- [mcpelauncher-ui-qt-git](pkgs/mcpelauncher-ui-qt) — Unofficial Minecraft Bedrock Edition launcher with GUI (Qt frontend).

## Overlays

The `custom/overlays` directory provides Nix overlays that are applied to the flake inputs. Current overlays in `custom/overlays/default.nix`:

- `additions` — Adds the repository's custom packages from `custom/pkgs` into the final package set (`pkgs`).
- `modifications` — Provides a place to modify or override existing packages (examples are included).
  - `opencode` — An overlay provided from the `opencode-src` flake input; exposes the `opencode` package set used for the Codex/Opencode agent tooling. Upstream repository: https://github.com/anomalyco/opencode
- `stable-packages` — Makes a stable `nixpkgs` set available as `pkgs.stable` (configured with `allowUnfree = true`).