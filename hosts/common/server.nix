{ config, lib, pkgs, ... }:

{
  environment.pathsToLink = [ "/libexec" ];

  # Enable chrony for servers, trying to resolve Ceph clock skew
  services.chrony.enable = true;

  imports = [
    ./default.nix
    ./modules/filesystem.nix
    ./modules/sshd.nix
  ];
}
