{ lib, ... }:
{
  imports = [ ./guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
