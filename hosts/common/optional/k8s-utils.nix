{
  config,
  lib,
  pkgs,
  ...
}: {
  environment.systemPackages = with pkgs; [
    unstable.fluxcd # flux CLI
    go-task # task runner
    unstable.k9s # kubernetes viewer tool
    kail # kubernetes tail
    ktop # kubernetes top
    unstable.kubectl # kubernetes CLI
    kubectl-doctor # kubernetes doctor
    kubectl-example # output example kubernetes types
    kubectl-view-allocations # view kubernetes allocations
    kubectl-view-secret # view kubernetes secrets without piping and decoding
    kubectl-cnpg # CNPG Plugin for kubectl
    kubecolor # colorize kubectl output
    unstable.kubernetes-helm # helm CLI
    kustomize # kustomize CLI for sadists
    kubectx # kubectx/kubens for switching namespaces/clusters
    sops # Secrets!
  ];
}
