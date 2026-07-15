# CLAUDE.md

Nix flake managing NixOS, nix-darwin, and Home Manager configurations.

## Layout & autowiring
- `flake.nix` — exports nixosConfigurations, darwinConfigurations, homeConfigurations, `packages`, `overlays`, formatter.
- Hosts: `configurations/nixos/<host>/` — auto-discovered as nixosConfigurations (except `retired/`). Home: `configurations/home/{personal,server,pinebook,work}`. Darwin: `configurations/darwin/work`.
- Modules in `modules/{nixos,home,darwin}` are auto-discovered by `lib/autowire.nix` and imported everywhere — no manual wiring. Everything is gated by enable options:
  - Components: `modules/nixos/components/*.nix` → `modules.nixos.<name>.enable`; `modules/home/components/*.nix` → `modules.home.<name>.enable` (named `terminal.*.nix`, `graphical.*.nix`, `scripts.*.nix`).
  - Groupings: `modules/nixos/{server,desktop,laptop}.nix` → `modules.machineType.<type>`; `modules/home/{personal,server,...}.nix` → `modules.homeType.<type>`. These enable sets of components.
  - New reusable component: add the file with an enable option, then enable it in the relevant machineType/homeType module (default) or a single host's config if host-specific. Users live in `modules/nixos/users/`.
  - Darwin modules mostly reuse `modules/nixos/components/*`.

## Custom packages & overlays
- Check nixpkgs first (including the rev pinned in `flake.lock`) before writing a custom package; when porting, base it on the upstream nixpkgs derivation.
- `custom/pkgs/<name>/`: `default.nix` + `versions.json` (never hardcode versions) + `update.sh`. Wire into `custom/pkgs/default.nix`; document in `custom/README.md`. `custom/pkgs/update.sh [name]` updates one/all.
- Overlays: `custom/overlays/`, wired via `custom/overlays/default.nix`.

## Secrets
- Real secrets (API keys, tokens): SOPS yaml in `secrets/` — never create/edit these yourself; tell the user what secret is needed and how to generate it.
- Obscurity-only values (domains, IPs) and anything needed at eval time: `secrets/secrets.nix` (git-crypt). Follow its existing structure.
- Never commit plaintext secrets.

## Claude Code module
- `modules/home/components/terminal.claude-code.nix` holds settings, MCP servers, permissions. Add new MCP servers/permissions to the default sets (not new options). Permission rules use the wildcard matching format.

## Conventions
- Minimal, localized edits; mirror nearby patterns and naming.
- Code should be self-explanatory; don't add comments to document intent that the code itself already makes clear.
- Format with `nix fmt` (nixfmt) before finishing.
- Verify: `nix eval` the affected config, e.g. `nix eval .#nixosConfigurations.<host>.config.system.build.toplevel.drvPath` or `.#homeConfigurations."w4cbe@<host>".activationPackage.drvPath`.
- Rebuilds (user runs): `nh os switch .`, `nh darwin switch .`, `nh home switch .`.
- CI: Forgejo workflows in `.forgejo/workflows/`; reference actions as plain `actions/<name>` (no `${{ github.server_url }}`).

## Shell commands (user runs fish)
- Interactive commands must be fish-compatible: `(…)` not `$(…)`; `and`/`or` not `&&`/`||`; `set -gx NAME VALUE` not `export`; no `[[ ]]` or `<(…)`. Script files may be bash/POSIX sh.
- If a task needs a utility that isn't on PATH, run it via `nix-shell -p <pkg> --run '…'` (or `nix run nixpkgs#<pkg>`). Never install temporary utilities globally or into a configuration just for a task.

## CodeGraph

If `.codegraph/` exists at the repo root, prefer CodeGraph over grep/find/Read for understanding or locating code:

- **MCP** (if loaded): `codegraph_explore("<names or question>")` — one call returns verbatim source, call paths, and dynamic-dispatch hops grep misses. If deferred, load it via tool search first.
- **Shell** (fallback): `codegraph explore "<names or question>"`.

No `.codegraph/` directory → skip CodeGraph.
