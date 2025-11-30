{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.k8sUtils;
in
{
  options.modules.k8sUtils = {
    enable = lib.mkEnableOption "k8s utilities packages";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.fluxcd # flux CLI
      pkgs.go-task # task runner
      # pkgs.k9s # kubernetes viewer tool (Check home-manager)
      pkgs.kail # kubernetes tail
      pkgs.ktop # kubernetes top
      pkgs.kubectl # kubernetes CLI
      pkgs.kubectl-doctor # kubernetes doctor
      pkgs.kubectl-example # output example kubernetes types
      # pkgs.kubectl-view-allocations # view kubernetes allocations
      pkgs.kubectl-view-secret # view kubernetes secrets without piping and decoding
      pkgs.kubectl-cnpg # CNPG Plugin for kubectl
      pkgs.kubecolor # colorize kubectl output
      pkgs.kubernetes-helm # helm CLI
      pkgs.kustomize # kustomize CLI for sadists
      pkgs.kubectx # kubectx/kubens for switching namespaces/clusters
      pkgs.sops # Secrets!
      pkgs.kubefetch # neofetch, but k8s
    ];
  };
}
