{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.opencode;

  zAiEnable = cfg.providers.z-ai.apiKeyFile != null;
  opencodeGoEnable = cfg.providers.opencode-go.apiKeyFile != null;

  mcpHelper = import ../../../lib/mcp-servers.nix {
    inherit pkgs lib;
    homeDir = config.home.homeDirectory;
  };

  # Keys are read by opencode from the file at startup, so they never enter
  # the Nix store or the shell environment.
  providers =
    lib.optionalAttrs zAiEnable {
      zai-coding-plan.options.apiKey = "{file:${cfg.providers.z-ai.apiKeyFile}}";
    }
    // lib.optionalAttrs opencodeGoEnable {
      opencode-go.options.apiKey = "{file:${cfg.providers.opencode-go.apiKeyFile}}";
    };
in
{
  options.modules.home.terminal.opencode = {
    enable = lib.mkEnableOption "OpenCode AI assistant configuration";

    providers = {
      z-ai.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding a z.ai API key, e.g.
          config.sops.secrets."providers/z-ai/apiKey".path.

          When set, OpenCode's built-in `zai-coding-plan` provider is
          authenticated: run `opencode -m zai-coding-plan/glm-5.3` (or pick it
          with /models). Plain `fr` resumes its sessions on their saved model.
        '';
      };

      opencode-go.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding an OpenCode Go API key, e.g.
          config.sops.secrets."providers/opencode-go/apiKey".path.

          When set, OpenCode's built-in `opencode-go` provider is
          authenticated: run `opencode -m opencode-go/<model>` (or pick it with
          /models). Plain `fr` resumes its sessions on their saved model.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.opencode ];

    home.file.".config/opencode/opencode.json".text = builtins.toJSON {
      "$schema" = "https://opencode.ai/config.json";
      provider = providers;
      mcp = mcpHelper.openCode;
    };
  };
}
