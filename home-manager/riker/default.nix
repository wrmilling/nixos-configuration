{ inputs, outputs, lib, config, pkgs, ... }:

{
  imports = [
    ./i3status-rust.nix
    ../common/terminal
    ../common/graphical
    ../common/scripts
    ../common/optional/armcord.nix
    ../common/optional/gaming-arm.nix
    ../common/optional/keybase.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = (_: true);
    };
  };

  home = {
    username = "w4cbe";
    homeDirectory = "/home/w4cbe";
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "23.05";
}
