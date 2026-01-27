{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.home.base;
in
{
  imports = lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./components);

  options.modules.home.base = {
    enable = lib.mkEnableOption "base Home-Manager configuration";
  };

  config = lib.mkIf cfg.enable {
    nixpkgs = {
      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.stable-packages
      ];
      config = {
        allowUnfree = true;
        # Workaround for https://github.com/nix-community/home-manager/issues/2942
        allowUnfreePredicate = _: true;
      };
    };

    home = {
      username = "w4cbe";
      homeDirectory = "/home/w4cbe";
    };

    programs.home-manager.enable = true;
  };
}
