{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.agentSandbox;
in
{
  options.modules.homeType.agentSandbox = {
    enable = lib.mkEnableOption "agent sandbox guest home-manager modules";

    zclaude = {
      enable = lib.mkEnableOption ''
        zclaude (z.ai GLM models) in the sandbox guest. Requires the host to
        share its z-ai key -- see modules/home/personal.nix.
      '';
    };

    oclaude = {
      enable = lib.mkEnableOption ''
        oclaude (OpenCode Go) in the sandbox guest. Requires the host to
        share its OpenCode Go key -- see modules/home/personal.nix.
      '';
    };

    maki = {
      enable = lib.mkEnableOption ''
        maki (AI coding agent) in the sandbox guest, pre-configured with the
        z.ai and OpenCode Go keys shared by the host -- see
        modules/home/personal.nix.
      '';
    };

    opencode = {
      enable = lib.mkEnableOption ''
        opencode (AI coding agent) in the sandbox guest, pre-configured with
        the OpenCode Go key shared by the host -- see
        modules/home/personal.nix.
      '';
    };

    codex = {
      enable = lib.mkEnableOption ''
        codex (OpenAI coding agent) in the sandbox guest, pre-configured with
        the OpenCode Go key shared by the host -- see
        modules/home/personal.nix.
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

    (lib.mkIf cfg.zclaude.enable {
      modules.home.terminal.claude-code.zclaude.apiKeyFile =
        "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
    })

    (lib.mkIf cfg.oclaude.enable {
      modules.home.terminal.claude-code.oclaude.apiKeyFile =
        "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";
    })

    (lib.mkIf cfg.maki.enable {
      modules.home.terminal.maki = {
        enable = true;
        zaiApiKeyFile = "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
        opencodeApiKeyFile = "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";
      };
    })

    (lib.mkIf cfg.opencode.enable {
      modules.home.terminal.opencode = {
        opencodeGoApiKeyFile = "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";
        zAiApiKeyFile = "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
      };
    })

    (lib.mkIf cfg.codex.enable {
      modules.home.terminal.codex = {
        opencodeGoApiKeyFile = "/home/w4cbe/.config/agent-sandbox/opencode-go/api-key";
        zAiApiKeyFile = "/home/w4cbe/.config/agent-sandbox/z-ai/api-key";
      };
    })
  ];
}
