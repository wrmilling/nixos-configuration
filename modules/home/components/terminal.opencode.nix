{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.opencode;

  # OpenAI-compatible models on OpenCode Go (Zen). These only expose
  # /v1/chat/completions, so they can't be routed through Claude Code.
  # Source: https://opencode.ai/docs/go/
  opencodeGoModels = {
    "glm-5.3" = {
      name = "GLM-5.3";
      limit = {
        context = 200000;
        output = 128000;
      };
    };
    "glm-5.3-flash" = {
      name = "GLM-5.3 Flash";
      limit = {
        context = 200000;
        output = 128000;
      };
    };
    "glm-5.2" = {
      name = "GLM-5.2";
      limit = {
        context = 200000;
        output = 128000;
      };
    };
    "kimi-k3" = {
      name = "Kimi K3";
      limit = {
        context = 256000;
        output = 64000;
      };
    };
    "kimi-k2.7-code" = {
      name = "Kimi K2.7 Code";
      limit = {
        context = 256000;
        output = 64000;
      };
    };
    "deepseek-v4-pro" = {
      name = "DeepSeek V4 Pro";
      limit = {
        context = 128000;
        output = 64000;
      };
    };
    "deepseek-v4-flash" = {
      name = "DeepSeek V4 Flash";
      limit = {
        context = 128000;
        output = 64000;
      };
    };
  };

  # OpenAI-compatible models on z.ai. Exposed via the GLM Coding Plan
  # /v1/chat/completions endpoint.
  zAiModels = {
    "glm-5.3" = {
      name = "GLM-5.3";
      limit = {
        context = 200000;
        output = 128000;
      };
    };
    "glm-5.3-flash" = {
      name = "GLM-5.3 Flash";
      limit = {
        context = 200000;
        output = 128000;
      };
    };
  };

  providers =
    lib.optionalAttrs (cfg.opencodeGoApiKeyFile != null) {
      opencode-go = {
        npm = "@ai-sdk/openai-compatible";
        name = "OpenCode Go";
        options = {
          baseURL = "https://opencode.ai/zen/go/v1";
          apiKey = "{env:OPENCODE_GO_API_KEY}";
        };
        models = opencodeGoModels;
      };
    }
    // lib.optionalAttrs (cfg.zAiApiKeyFile != null) {
      "z-ai" = {
        npm = "@ai-sdk/openai-compatible";
        name = "z.ai";
        options = {
          baseURL = "https://api.z.ai/api/coding/paas/v4";
          apiKey = "{env:Z_AI_API_KEY}";
        };
        models = zAiModels;
      };
    };

  opencodeConfig = {
    "$schema" = "https://opencode.ai/config.json";
    inherit providers;
  };

  anyKey = cfg.opencodeGoApiKeyFile != null || cfg.zAiApiKeyFile != null;
in
{
  options.modules.home.terminal.opencode = {
    enable = lib.mkEnableOption "OpenCode AI assistant configuration";

    opencodeGoApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing an OpenCode Go API key (e.g. a
        sops-nix decrypted secret path such as
        config.sops.secrets."providers/opencode-go/apiKey".path).

        When set, OpenCode is configured with the OpenCode Go provider
        pre-populated and the API key is exported as OPENCODE_GO_API_KEY so
        /v1/chat/completions requests from the configured models succeed.
      '';
    };

    zAiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing a z.ai API key (e.g. a sops-nix
        decrypted secret path such as
        config.sops.secrets."providers/z-ai/apiKey".path).

        When set, OpenCode is configured with the z.ai provider
        pre-populated (using the GLM Coding Plan OpenAI-compatible endpoint)
        and the API key is exported as Z_AI_API_KEY.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional anyKey pkgs.opencode;

    # Load each key at shell startup so the plaintext never lands in the Nix
    # store; opencode inherits them from the launching shell.
    programs.fish.interactiveShellInit = lib.mkIf anyKey (
      lib.concatStringsSep "\n" (
        lib.optional (cfg.opencodeGoApiKeyFile != null) ''
          if test -r ${cfg.opencodeGoApiKeyFile}
              set -gx OPENCODE_GO_API_KEY (cat ${cfg.opencodeGoApiKeyFile})
          end
        ''
        ++ lib.optional (cfg.zAiApiKeyFile != null) ''
          if test -r ${cfg.zAiApiKeyFile}
              set -gx Z_AI_API_KEY (cat ${cfg.zAiApiKeyFile})
          end
        ''
      )
    );

    home.file.".config/opencode/opencode.json" = lib.mkIf anyKey {
      text = builtins.toJSON opencodeConfig;
    };

    modules.home.scripts.opencode-fr.enable = anyKey;
  };
}
