{ pkgs, ... }: 

{
  imports = [
    ./git.nix
    ./tmux.nix
  ];
  home.packages = with pkgs; [
    
  ];
}