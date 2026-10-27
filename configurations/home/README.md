# Home Manager

Home Manager configurations. Each directory enables a `homeType` module
(`modules.homeType.<type>.enable` in `modules/home/<type>.nix`) and is reused by
multiple hosts via `homeConfigurations` in `flake.nix`.

## Configurations

- [personal](personal) — `homeType.personal`; desktop/laptop hosts (bender, donnager, icarus, enterprise, loki)
- [pinebook](pinebook) — `homeType.pinebook`; Pinebook Pro hosts (riker, serenity)
- [server](server) — `homeType.server`; headless servers (bart, bob, goku, isaac, jack, khan, linus, owen, nk3s-amd64-*)
- [work](work) — `homeType.darwin`; work-mac only
