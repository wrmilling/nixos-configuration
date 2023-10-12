{ config, pkgs, lib, ... }:
let
  secrets = import ../../../secrets/secrets.nix;
in
{
  # This is required so that pod can reach the API server (running on port 6443 by default)
  networking.firewall.allowedTCPPorts = [ 6443 ];
  services.k3s = {
    enable = true;
    package = pkgs.unstable.k3s;
    role = "agent";
    serverAddr = lib.mkDefault secrets.k3s.server.addr;
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--node-label \"k3s-upgrade=false\""; # Optionally add additional args to k3s
  };

  environment.systemPackages = [ pkgs.unstable.k3s ];
}