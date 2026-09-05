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
    graphical.enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Include development tools that need a display. Set false on headless hosts.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.dtc
      pkgs.nixpkgs-review
      pkgs.go
      pkgs.pre-commit
      pkgs.gh
      pkgs.diffoscopeMinimal
      pkgs.jq
    ]
    ++ lib.optionals cfg.graphical.enable [
      pkgs.vscode
    ];
  };
}
