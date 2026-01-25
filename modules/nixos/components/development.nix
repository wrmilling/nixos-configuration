{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.development;
in
{
  options.modules.nixos.development = {
    enable = lib.mkEnableOption "development packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.vscode
      pkgs.dtc
      pkgs.nixpkgs-review
      pkgs.go
      pkgs.pre-commit
      pkgs.gh
      pkgs.diffoscopeMinimal
    ];
  };
}