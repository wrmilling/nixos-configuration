{
  config,
  lib,
  pkgs,
  outputs,
  ...
}:
{
  imports = [
    ./users/w4cbe.nix
    ./modules/terminal.nix
    ./modules/sops.nix
  ];

  # NixPackage Setup
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.stable-packages
      # outputs.overlays.lilyinstarlight-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Basic environment.
  environment.systemPackages = [ ];

  #
  # Misc settings
  # -------------
  #
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Chicago";

  security.sudo.enable = true;
  security.polkit.enable = true;

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
}
