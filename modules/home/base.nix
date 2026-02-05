{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  secrets,
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
    nix = {
      package = pkgs.lix;
      settings = {
        substituters = [
          secrets.nixcache.hostname
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          secrets.nixcache.public_key
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      };
    };

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
