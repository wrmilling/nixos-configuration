{ config, lib, pkgs, ... }:

{
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };
}