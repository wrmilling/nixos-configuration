{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    pkgs.vscode
    pkgs.dtc
    pkgs.nixpkgs-review
    pkgs.go
    pkgs.pre-commit
    pkgs.gh
  ];
}
