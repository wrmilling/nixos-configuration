{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.darwin.base;
in
{
  imports = [
    ../nixos/components/terminal.nix
    ../nixos/components/k8s-utils.nix
  ];

  options.modules.darwin.base = {
    enable = lib.mkEnableOption "base darwin configuration";
  };

  config = lib.mkIf cfg.enable {
    # Default 
    modules = {
      nixos.terminal.enable = true;
      nixos.k8sUtils.enable = true;
    };
  };
}
