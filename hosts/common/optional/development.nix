{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    vscode
    dtc
    nixpkgs-review
    go
  ];
}
