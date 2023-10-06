{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.kubectl
    unstable.fluxcd
    unstable.kubernetes-helm-wrapped
    kubectx
    stern
    sops
    k9s
  ];
}
