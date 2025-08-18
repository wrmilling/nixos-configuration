{ pkgs, ... }:
{
  imports = [
    ./onedrive-rclone.nix
    ./procinfo.nix
  ];
}
