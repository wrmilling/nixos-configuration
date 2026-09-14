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

      # nixpkgs-unstable currently has qemu-vm's shared directories on virtiofsd,
      # which has no Darwin build (NixOS/nixpkgs#552774) and breaks eval here until
      # the revert (NixOS/nixpkgs#562444) reaches our pin. Build the builder itself
      # from the frozen nixpkgs-stable input instead; it only affects the builder
      # VM's own toolchain, not what gets built on it.
      package =
        inputs.nixpkgs-stable.legacyPackages.${pkgs.stdenv.hostPlatform.system}.darwin.linux-builder;

      # The builder's qcow2 grows on demand and never shrinks, and its in-guest
      # auto-GC only fires below nix.settings.min-free (1GiB), so left alone it
      # creeps up to diskSize and stays there. Raising min-free would rebuild
      # the aarch64-linux guest; wiping the image will not.
      ephemeral = true;

      # Only knobs that leave the guest's toplevel untouched belong here --
      # anything guest-side (nix.settings, extra substituters, packages) has to
      # be built for aarch64-linux, which is what this builder exists to enable.
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
