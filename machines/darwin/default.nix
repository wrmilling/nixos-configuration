# hosts/YourHostName/default.nix
{ pkgs, config, inputs, outputs, lib, secrets, ... }:
{
  imports = 
  [
    inputs.home-manager.darwinModules.home-manager
  ];

  security.pki.certificateFiles = [ "/etc/ssl/thd_combined.pem" ];

  # home-manager = {
  #   extraSpecialArgs = { inherit inputs outputs secrets; };
  #   users.WRM6768 = import ../../home-manager/darwin;
  # };

  #package config
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = (_: true);
    };
  };

  nix = {
    # package = lib.mkDefault pkgs.nix;
    package = pkgs.nixVersions.nix_2_16;
    settings = {
      experimental-features = [ "nix-command" "flakes" "repl-flake" ];
      warn-dirty = false;
      sandbox = "relaxed";
    };

    configureBuildUsers = true;

    gc = {
      automatic = true;
      interval = { Weekday = 0; Hour = 2; Minute = 0; };
      options = "--delete-older-than 30d";
    };
  };

  services.activate-system.enable = true;
  services.nix-daemon.enable = true;
  programs.nix-index.enable = true;

  environment = {
    systemPackages = [
        pkgs.coreutils
        pkgs.fish
        pkgs.git
        pkgs.vim
        pkgs.home-manager
        ];
    shells = [ pkgs.bashInteractive pkgs.fish ];
    variables.EDITOR = "${lib.getBin pkgs.vim}/bin/vim";
  };

  programs = {
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  # Use touch ID for sudo auth
  security.pam.enableSudoTouchIdAuth = true;
}