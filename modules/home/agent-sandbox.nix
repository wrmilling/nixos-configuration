{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.agentSandbox;

  # Matches the paths modules/home/personal.nix's activation scripts copy to,
  # which the host shares into the guest through extraShares.
  zAiKey = "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
  opencodeGoKey = "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";
in
{
  options.modules.homeType.agentSandbox = {
    enable = lib.mkEnableOption "agent sandbox guest home-manager modules";

    providers = {
      z-ai.enable = lib.mkEnableOption ''
        the z.ai provider for every harness in the guest (zclaude, zcodex,
        OpenCode's zai-coding-plan, maki). Requires the host to share its
        z.ai key -- see modules/home/personal.nix.
      '';

      opencode-go.enable = lib.mkEnableOption ''
        the OpenCode Go provider for every harness in the guest (oclaude,
        ocodex, OpenCode's opencode-go, maki). Requires the host to share its
        OpenCode Go key -- see modules/home/personal.nix.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      modules = {
        home.base.enable = true;
        home.terminal.fish.enable = true;
        home.terminal.general.enable = true;
        home.terminal.git.enable = true;
        home.terminal.gpg.enable = true;
        home.terminal.k8s-utils.enable = true;
        home.terminal.development.enable = true;
        home.terminal.starship.enable = true;
        home.terminal.vim.enable = true;
        home.terminal.claude-code.enable = true;
        home.terminal.codex.enable = true;
        home.terminal.opencode.enable = true;
        home.terminal.maki.enable = true;
      };

      # gpg uses the agent socket forwarded from the host, which holds the
      # smartcard. A local agent would bind that path first.
      services.gpg-agent.enable = lib.mkForce false;

      # An unexpired generation is a GC root, so the guest's nix.gc cannot
      # collect it.
      services.home-manager.autoExpire = {
        enable = true;
        frequency = "weekly";
      };

      # Supervised so systemd can stop it on shutdown; a foreground process gets
      # killed by the power-off before it flushes pane state to session.json.
      systemd.user.services.herdr = {
        Unit.Description = "Herdr headless server";
        Install.WantedBy = [ "default.target" ];
        Service = {
          ExecStart = "${pkgs.herdr}/bin/herdr server";
          ExecStop = "${pkgs.herdr}/bin/herdr server stop";
          WorkingDirectory = "/home/w4cbe/workspace";
          Restart = "on-failure";
        };
      };
    })

    (lib.mkIf cfg.providers.z-ai.enable {
      modules.home.terminal = {
        claude-code.providers.z-ai.apiKeyFile = zAiKey;
        codex.providers.z-ai.apiKeyFile = zAiKey;
        opencode.providers.z-ai.apiKeyFile = zAiKey;
        maki.providers.z-ai.apiKeyFile = zAiKey;
      };
    })

    (lib.mkIf cfg.providers.opencode-go.enable {
      modules.home.terminal = {
        claude-code.providers.opencode-go.apiKeyFile = opencodeGoKey;
        codex.providers.opencode-go.apiKeyFile = opencodeGoKey;
        opencode.providers.opencode-go.apiKeyFile = opencodeGoKey;
        maki.providers.opencode-go.apiKeyFile = opencodeGoKey;
      };
    })
  ];
}
