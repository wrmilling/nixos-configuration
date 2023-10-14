{ config, pkgs, lib, ... }:
let
  secrets = import ../../../secrets/secrets.nix;
  k3s-package = pkgs.unstable.k3s;
in
{
  # This is required so that pod can reach the API server (running on port 6443 by default) and Metrics (10250)
  networking.firewall.allowedTCPPorts = [ 443 6443 7472 7946 10250 ];
  networking.firewall.allowedUDPPorts = [ 7472 7946 ];
  services.k3s = {
    enable = true;
    package = k3s-package;
    role = "agent";
    serverAddr = lib.mkDefault secrets.k3s.server.addr;
    token = lib.mkDefault secrets.k3s.agent.nodeToken;
    extraFlags = "--node-label \"k3s-upgrade=false\""; # Optionally add additional args to k3s
  };

  environment.systemPackages = [ k3s-package ];
}