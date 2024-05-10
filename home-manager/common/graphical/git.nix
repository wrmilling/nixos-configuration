{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = with pkgs; [ git-credential-manager ];
  # This assumes the terminal/git.nix is also configured.
  programs.git.extraConfig.credential.helper = "${pkgs.git-credential-manager}/bin/git-credential-manager";
}
