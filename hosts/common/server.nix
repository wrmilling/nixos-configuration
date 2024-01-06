{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.pathsToLink = ["/libexec"];

  imports = [
    ./default.nix
    ./modules/chrony.nix
    ./modules/filesystem.nix
    ./modules/sshd.nix
  ];
}
