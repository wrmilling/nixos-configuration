{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.k3sAgentArm;
  k3s-package = pkgs.k3s_1_34;
in
{
  imports = [ ./k3s-firewall.nix ];

  options.modules.nixos.k3sAgentArm = {
    enable = lib.mkEnableOption "k3s agent (arm) packages / settings";
    tokenFile = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "File path to the node tokenFile secret";
    };
    serverAddr = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "k3s master node server address";
    };
  };

  config = lib.mkIf cfg.enable {
    modules = {
      nixos.k3sFirewall.enable = true;
    };

    services.k3s = {
      enable = true;
      package = k3s-package;
      role = "agent";
      serverAddr = config.modules.k3sAgentArm.serverAddr;
      tokenFile = config.modules.k3sAgentArm.tokenFile;
      extraFlags = "--node-label \"k3s-upgrade=false\" --node-taint \"arm=true:NoExecute\""; # Optionally add additional args to k3s
      extraKubeletConfig = {
        imageMaximumGCAge = "168h";
      };
    };

    environment.systemPackages = [ k3s-package ];
  };
}