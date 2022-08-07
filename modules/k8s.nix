{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
    fluxcd
    helm
    stern
    sops
    k9s
}
