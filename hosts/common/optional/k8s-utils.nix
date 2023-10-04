{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    kubectl
    fluxcd
    unstable.kubernetes-helm-wrapped
    stern
    sops
    k9s
  ];
}
