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
  cfg = config.modules.nixos.base;
in
{
  imports = lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./components)
    ++ lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./users);

  options.modules.nixos.base = {
    enable = lib.mkEnableOption "base NixOS configuration";
  };

  config = lib.mkIf cfg.enable {
    # Default 
    modules = {
      users.w4cbe.enable = true;
      nixos.terminal.enable = true;
      nixos.sops.enable = true;
    };

    # Nix Setup
    nix = {
      package = pkgs.lix;
      settings = {
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [ "nix-command" "flakes" ];
        substituters = [
          secrets.nixcache.hostname
          "https://cache.nixos.org"
        ];
        trusted-public-keys = [
          secrets.nixcache.public_key
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        ];
      };
      settings.trusted-users = [
        "root"
        "@wheel"
      ];
    };

    # NixPackage Setup
    nixpkgs = {
      overlays = [
        outputs.overlays.additions
        outputs.overlays.modifications
        outputs.overlays.stable-packages
      ];
      config = {
        allowUnfree = true;
      };
    };

    # Misc Settings
    environment.pathsToLink = [ "/libexec" ];

    i18n = {
      defaultLocale = "en_US.UTF-8";
    };

    time.timeZone = "America/Chicago";

    security.sudo.enable = true;
    security.polkit.enable = true;
  };
}
