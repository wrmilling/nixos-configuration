{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.darwin.linuxBuilder;
  builder = config.nix.linux-builder;

  diskSizeMB = 40960;
  # Wipe the qcow2 at start once it passes ~75% of diskSize, instead of every start.
  wipeThresholdBytes = diskSizeMB * 1024 * 1024 * 3 / 4;
in
{
  options.modules.darwin.linuxBuilder = {
    enable = lib.mkEnableOption "nix-darwin's aarch64-linux builder VM";
  };

  # Deliberately independent of modules.darwin.agentSandbox: the sandbox runner
  # is an aarch64-linux closure, so the builder has to be activatable by a
  # switch that does not already need it.
  config = lib.mkIf cfg.enable {
    nix.linux-builder = {
      enable = true;
      systems = [ "aarch64-linux" ];

      # unstable puts qemu-vm shares on virtiofsd, which has no Darwin build, so
      # eval breaks until the revert lands. NixOS/nixpkgs#552774, #562444.
      package =
        inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.darwin.linux-builder;

      # The qcow2 only grows and in-guest auto-GC fires too late; the size-capped
      # wipe below bounds it without refetching the store on every restart.
      ephemeral = false;

      # Darwin-side knobs only: anything guest-side needs an aarch64-linux build,
      # which is what this builder exists to provide.
      config = {
        virtualisation.cores = 8;
        virtualisation.darwin-builder = {
          memorySize = 8192;
          diskSize = diskSizeMB;
        };
      };
    };

    launchd.daemons.linux-builder.script = lib.mkBefore ''
      img=${builder.workingDirectory}/${builder.package.nixosConfig.networking.hostName}.qcow2
      if [ -e "$img" ] && [ "$(/usr/bin/stat -f %z "$img")" -gt ${toString wipeThresholdBytes} ]; then
        rm -f "$img"
      fi
    '';

    # The Mac store already holds the guest closure; copy it over loopback
    # rather than have the builder refetch it from cache.nixos.org.
    nix.settings.builders-use-substitutes = lib.mkForce false;
  };
}
