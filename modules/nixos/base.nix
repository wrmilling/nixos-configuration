{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  ...
}:
let
  cfg = config.modules.base;
in
{
  imports = lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./components)
    ++ lib.filter 
    (n: lib.strings.hasSuffix ".nix" n)
    (lib.filesystem.listFilesRecursive ./users);

  options.modules.base = {
    enable = lib.mkEnableOption "base NixOS configuration";
  };

  config = lib.mkIf cfg.enable {
    # Default 
    modules = {
      users.w4cbe.enable = true;
      terminal.enable = true;
      sops.enable = true;
    };

    # Nix Setup
    nix = {
      package = pkgs.lix;
      settings = {
        auto-optimise-store = lib.mkDefault true;
        experimental-features = [ "nix-command" "flakes" ];
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
