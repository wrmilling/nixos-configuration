{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.darwin.linuxBuilder;
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

      # The qcow2 only grows, and in-guest auto-GC fires too late to stop it.
      # Raising min-free would rebuild the aarch64-linux guest; a wipe will not.
      ephemeral = true;

      # Darwin-side knobs only: anything guest-side needs an aarch64-linux build,
      # which is what this builder exists to provide.
      config = {
        virtualisation.cores = 8;
        virtualisation.darwin-builder = {
          memorySize = 8192;
          diskSize = 40960;
        };
      };
    };
  };
}
