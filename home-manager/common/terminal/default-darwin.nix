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
  home.packages = with pkgs; [ 
    cloudfoundry-cli
  ];
}
