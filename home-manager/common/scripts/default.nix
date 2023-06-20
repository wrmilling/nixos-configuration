{ pkgs, ... }:

{
  imports = [
    ./bsodlock.nix
    ./onedrive-rclone.nix
    ./procinfo.nix
  ];
}
