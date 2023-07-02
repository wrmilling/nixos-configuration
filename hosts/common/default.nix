{ config, pkgs, ... }:

{
  imports =
    [
      ./modules/users.nix
      ./modules/terminal.nix
    ];

  # Basic environment.
  environment.systemPackages = with pkgs; [

  ];

  # Ensure I always have fish for default user
  programs.fish = {
    enable = true;
    vendor = {
      completions.enable = true;
      config.enable = true;
      functions.enable = true;
    };
  };

  #
  # Misc settings
  # -------------
  #
  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  time.timeZone = "America/Chicago";

  security.sudo.enable = true;

  nixpkgs.config.allowUnfree = true;

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
  };

}
