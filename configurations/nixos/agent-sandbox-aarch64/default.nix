{ lib, ... }:
{
  imports = [ ../agent-sandbox/guest.nix ];

  nixpkgs.hostPlatform = lib.mkDefault "aarch64-linux";
}
