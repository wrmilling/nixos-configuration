{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    unstable.kubectl
    unstable.fluxcd
    unstable.kubernetes-helm-wrapped
    stern
    sops
    k9s
  ];
}
