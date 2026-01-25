{
  pkgs,
  config,
  inputs,
  outputs,
  lib,
  secrets,
  ...
}:
{
  imports = [
    ./homebrew.nix
  ];

  modules = {
    darwin.work.enable = true;
  };

  security.pki.certificateFiles = [ ../../../secrets/certs/cert.pem ];
  programs.nix-index.enable = true;

  system.primaryUser = "${secrets.hosts.work-mac.username}";

  #package config
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  nix = {
    package = lib.mkDefault pkgs.nix;
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      warn-dirty = false;
      sandbox = "relaxed";
      trusted-users = [
        "${secrets.hosts.work-mac.username}"
      ];
    };
  };

  environment = {
    systemPackages = [
      pkgs.coreutils
      pkgs.fish
      pkgs.git
      pkgs.vim
      pkgs.home-manager
      pkgs.openssh
      pkgs.jdk8
      pkgs.jdk11
      pkgs.jdk17
      pkgs.jdk21
    ];
    shells = [
      pkgs.bashInteractive
      pkgs.fish
    ];
    shellAliases = {
      git = "/usr/bin/git";
    };
    variables.EDITOR = "${lib.getBin pkgs.vim}/bin/vim";
  };

  fonts.packages = [
    pkgs.source-code-pro
    pkgs.font-awesome_4
    pkgs.monaspace
  ];

  programs = {
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  # Use touch ID for sudo auth
  security.pam.services.sudo_local.touchIdAuth = true;

  ids.gids.nixbld = 30000;
  system.stateVersion = 5;
}
