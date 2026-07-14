{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.forgejoRunner;
in
{
  options.modules.nixos.forgejoRunner = {
    enable = lib.mkEnableOption "forgejo actions runner";

    domain = lib.mkOption {
      type = lib.types.str;
      description = "Domain of the Forgejo instance this runner registers against.";
    };

    runnerTokenFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to the file containing the forgejo runner registration token.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;

    # act_runner's actions/cache server needs a pinned port reachable from job containers, but only via Docker's bridge interfaces - never the public one.
    networking.firewall.extraCommands = ''
      iptables -A nixos-fw -i docker0 -p tcp --dport 41230 -j nixos-fw-accept
      iptables -A nixos-fw -i br-+    -p tcp --dport 41230 -j nixos-fw-accept
    '';
    networking.firewall.extraStopCommands = ''
      iptables -D nixos-fw -i docker0 -p tcp --dport 41230 -j nixos-fw-accept || true
      iptables -D nixos-fw -i br-+    -p tcp --dport 41230 -j nixos-fw-accept || true
    '';

    services.gitea-actions-runner = {
      package = pkgs.forgejo-runner;
      instances.${config.networking.hostName} = {
        enable = true;
        name = config.networking.hostName;
        settings = {
          runner.fetch_interval = "15s";
          container.docker_host = "automount";
          cache = {
            enabled = true;
            host = "host.docker.internal";
            proxy_port = 41230;
          };
        };
        labels = [
          "alpine:docker://alpine:3.23.4"
          "alpine-latest:docker://alpine:latest"
          "alpine-tokyo:docker://${cfg.domain}/wrmilling/alpine-tokyo:3.23.4-3"
          "alpine-tokyo-latest:docker://${cfg.domain}/wrmilling/alpine-tokyo:latest"
          "ubuntu-latest:docker://node:18-bullseye"
        ];
        url = "https://${cfg.domain}";
        tokenFile = cfg.runnerTokenFile;
      };
    };
  };
}
