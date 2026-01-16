{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.darwin.work;
in
{
  # Re-use the NixOS Module where possible
  options.modules.darwin.work = {
    enable = lib.mkEnableOption "darwin work modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      darwin.base.enable = true;
      nixos.terminal.enable = true;
      nixos.k8sUtils.enable = true;
    };
  };
}
