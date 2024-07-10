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
    ../common/modules/terminal.nix
    ../common/optional/k8s-utils.nix
    ./homebrew.nix
  ];

  security.pki.certificateFiles = [ ../../secrets/certs/cert.pem ];
  services.activate-system.enable = true;
  services.nix-daemon.enable = true;
  programs.nix-index.enable = true;

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
        "repl-flake"
      ];
      warn-dirty = false;
      sandbox = "relaxed";
    };

    configureBuildUsers = true;
  };

  environment = {
    systemPackages = [
      pkgs.coreutils
      pkgs.fish
      pkgs.git
      pkgs.vim
      pkgs.home-manager
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

  fonts.packages = with pkgs; [
    source-code-pro
    font-awesome_4
    monaspace
  ];

  programs = {
    bash.enable = true;
    fish.enable = true;
    zsh.enable = true;
  };

  # Use touch ID for sudo auth
  security.pam.enableSudoTouchIdAuth = true;
}
