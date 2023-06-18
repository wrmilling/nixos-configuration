{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
    fluxcd
    kubernetes-helm-wrapped
    stern
    sops
    k9s
  ];
}
