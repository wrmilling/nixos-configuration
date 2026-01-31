# AGENTS.md

Guidance for AI agents working in this repository.

This repository contains a Nix flake that manages NixOS hosts, nix-darwin (macOS) hosts, and Home Manager configurations.

## Project context / design
- Flake entry: `flake.nix` (exports NixOS, nix-darwin, and Home Manager configurations; provides `overlays`, `pkgs`, and formatters).
- Host / NixOS configs live under `configurations/nixos/*` (e.g., `configurations/nixos/bob`, `configurations/nixos/isaac`, `configurations/nixos/icarus`, `configurations/nixos/nk3s-amd64-0`).
- Home Manager configs live under `configurations/home/*` (e.g., `configurations/home/personal`, `configurations/home/server`).
- Darwin configs live under `configurations/darwin/*` (e.g., `configurations/darwin/work`).
- Shared modules for Darwin, Home Manager, and NixOS are under `modules/*` (e.g., `modules/darwin`, `modules/home`, `modules/nixos`).
  - Shared NixOS modules are grouped by machineType in the root of `modules/nixos/` with the shared features/components in the `modules/nixos/components` directory. Users are defined in `modules/nixos/users`. Default to including new modules in the relavant machineType configurations unless the module is to be used by only a single host, then import to just that host's confiuration. 
  - Shared Home Manager modules follows the same scheme as Shared NixOS modules except it uses the nomenclature of homeType instead of machineType, the same module import rules apply.
  - Shared Darwin modules primarily import NixOS components and can reference them from the `modules/nixos/components` directory. 
- Custom overlays and packages live in `custom/*`; aggregated by `custom/*/default.nix` in respective folders.
- Secrets have two types in this repository:
  - Secrets like API Keys, Tokens, and the like should be encrypted via SOPS and should only be done by the human in the loop. AIs should prompt the user to update secrets and provide guidance as to what secrets need to be created and any special commands or documentation which can be used to generate the secret. 
  - Secrets which are only secret for obscurity purposes (e.g. a domain name, an IP address) should be stored in `secrets/secrets.nix` which is encrypted via git-crypt. Follow existing file structure when adding new entries. This is also where secrets go when they are required at evaluation time of the repo and cannot be imported / injected via a file at runtime of the application. 

## Conventions for changes
- Follow the existing directory structure and design when adding or modifying functionality.
  - Host-specific logic goes in the corresponding folder under `configurations/nixos/<host>/`. 
  - Reusable Home Manager, NixOS, and Darwin bits belong under `modules/<darwin|home|nixos>` directories exposed through their machineType, homeType, or darwin configurations. New reusable modules should follow the same pattern
  - New overlays go in `custom/overlays/` and should be wired via `custom/overlays/default.nix`.
  - New custom packages go in `custom/pkgs/` and should be referenced by `custom/pkgs/default.nix`.
- Prefer minimal, localized edits; avoid large-scale refactors unless requested.
- Keep options/naming/style consistent with nearby files; mirror patterns already used in this repo.
- Do not commit secrets; use the existing secrets pattern described in the Project context / design.

## Shell command requirements (important)
- The local terminal is fish shell on NixOS. All commands you ask the user to run in a terminal MUST be fish-compatible.
- Guidelines for fish-compatible commands:
  - Use command substitution with `(…)` instead of `$(…)`.
  - Use `and` / `or` instead of `&&` / `||`.
  - Use `;` to sequence commands when appropriate.
  - Export environment variables with `set -gx NAME VALUE` (not `export NAME=VALUE`). Local vars: `set -l`.
  - Arrays/lists are space-separated: `set -l PATHS a b c`.
  - Avoid bash-only idioms like `[[ … ]]`, process substitution `<(…)`, or `source <(curl …)`.
  - If you provide a script file, it can be POSIX sh/bash; only interactive commands shown for the terminal must be fish-compatible.

## Common Nix flows
- Format Nix: `nix fmt`
- Update inputs: `nix flake update`
- Evaluate/check (if checks are defined): `nix flake check`
- Rebuild/switch:
  - NixOS host: `nh os switch .`
  - macOS (nix-darwin): `nh darwin switch .`
  - Home Manager (standalone): `nh home switch .`

## PR/commit guidance
- Keep PRs narrowly scoped and reference which host(s)/module(s) are affected.
- Include a brief note on how to apply or test (commands must be fish-compatible).

## Quick checklist for agents
- [ ] Confirm the change location matches the existing structure (hosts/common, modules, overlays, pkgs, HM features).
- [ ] Generate only fish-compatible terminal commands in instructions and examples.
- [ ] Keep edits minimal and consistent with nearby patterns.
- [ ] Avoid committing secrets; use the established secrets mechanism.
