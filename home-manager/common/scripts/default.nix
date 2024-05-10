{ pkgs, ... }:
{
  imports = [
    ./bsodlock.nix
    ./i3exit.nix
    ./onedrive-rclone.nix
    ./procinfo.nix
  ];
}
