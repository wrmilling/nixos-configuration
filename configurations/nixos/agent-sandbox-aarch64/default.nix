{ lib, pkgs, ... }:
{
  imports = [ ../agent-sandbox/guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";

  environment.systemPackages = [
    pkgs.cloudfoundry-cli
    pkgs.shiftleft-sl
  ];
}
