{ pkgs, ... }:
{
  imports = [
    ./atuin.nix
    ./fish.nix
    ./general.nix
    ./git.nix
    ./gpg-mac.nix
    ./starship.nix
    ./tmux.nix
    ./vim.nix
  ];
  home.packages = [
    pkgs.cloudfoundry-cli
    pkgs.google-cloud-sdk
    # pkgs.azure-cli
    pkgs.rancher
    pkgs.slides-git
    pkgs.graph-easy
  ];
}
