# Home Manager

Home Manager configurations. Each directory maps a `homeType` module
(`modules.home.<type>.enable` in `modules/home/<type>.nix`) and is reused by
multiple hosts via `homeConfigurations` in `flake.nix`.

## Configurations

- [personal](personal) — desktop/laptop hosts (bender, donnager, icarus, enterprise, loki, work-mac)
- [pinebook](pinebook) — Pinebook Pro hosts (riker, serenity)
- [server](server) — headless servers (bart, bob, goku, isaac, jack, khan, linus, owen, nk3s-amd64-*)
- [work](work) — work-mac only
