{
  config,
  lib,
  pkgs,
  ...
}:
{
  # Re-use the NixOS Module where possible
  imports = [
    ../nixos/components/terminal.nix
    ../nixos/components/k8s-utils.nix
  ];
}
