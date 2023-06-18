{ pkgs, ... }: 

{
  imports = [
    ./atuin.nix
    ./git.nix
    ./tmux.nix
  ];
  home.packages = with pkgs; [
    
  ];
}