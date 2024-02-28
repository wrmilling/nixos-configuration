{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    fluxcd # flux CLI
    go-task # task runner
    k9s # kubernetes viewer tool
    kail # kubernetes tail
    ktop # kubernetes top
    kubectl # kubernetes CLI
    kubectl-doctor # kubernetes doctor
    kubectl-example # output example kubernetes types
    kubectl-view-allocations # view kubernetes allocations
    kubectl-view-secret # view kubernetes secrets without piping and decoding
    kubectl-cnpg # CNPG Plugin for kubectl
    kubecolor # colorize kubectl output
    kubernetes-helm # helm CLI
    kustomize # kustomize CLI for sadists
    kubectx # kubectx/kubens for switching namespaces/clusters
    sops # Secrets!
    kubefetch # neofetch, but k8s
  ];
}
