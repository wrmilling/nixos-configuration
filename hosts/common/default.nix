{ config, pkgs, outputs, ... }:

{
  imports =
    [
      ./modules/users.nix
      ./modules/terminal.nix
    ];


  # NixPackage Setup
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
    };
  };

  # Basic environment.
  environment.systemPackages = with pkgs; [

  ];

  #
  # Misc settings
  # -------------
  #
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Chicago";

  security.sudo.enable = true;
  security.pam.enableSSHAgentAuth = true;
  security.polkit.enable = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    settings.trusted-users = [ "root" "@wheel" ];
  };

}
