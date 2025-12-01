{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  imports = [
    ../common/terminal/fish.nix
    ../common/terminal/general.nix
    ../common/terminal/starship.nix
    ../common/terminal/vim.nix
  ];

  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.stable-packages
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "haley";
    homeDirectory = "/home/haley";
    packages = [
      pkgs.google-chrome
    ];
  };

  programs.home-manager.enable = true;

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  home.stateVersion = "24.11";
}
