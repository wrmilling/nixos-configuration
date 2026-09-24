{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.codex;

  opencodeGoEnable = cfg.opencodeGoApiKeyFile != null;
  zAiEnable = cfg.zAiApiKeyFile != null;

  # Wraps the Codex CLI against OpenCode Go's OpenAI-compatible
  # /v1/chat/completions endpoint. Mirrors the oclaude wrapper shape; routes
  # through @ai-sdk/openai-compatible-style providers rather than the
  # Anthropic /v1/messages endpoint.
  ocodexPackage = pkgs.writeShellApplication {
    name = "ocodex";
    runtimeInputs = [
      pkgs.codex
      pkgs.coreutils
    ];
    text = ''
      keyfile=${lib.escapeShellArg (toString cfg.opencodeGoApiKeyFile)}
      if [ ! -r "$keyfile" ]; then
        echo "ocodex: OpenCode Go API key not readable at $keyfile" >&2
        echo "ocodex: ensure sops-nix is active and the providers/opencode-go/apiKey secret is configured." >&2
        exit 1
      fi

      export OPENAI_API_KEY="$(cat "$keyfile")"
      export OPENAI_BASE_URL="https://opencode.ai/zen/go/v1"

      exec ${pkgs.codex}/bin/codex "$@"
    '';
  };

  # Wraps the Codex CLI against z.ai's OpenAI-compatible endpoint
  # (GLM Coding Plan /v1/chat/completions).
  zcodexPackage = pkgs.writeShellApplication {
    name = "zcodex";
    runtimeInputs = [
      pkgs.codex
      pkgs.coreutils
    ];
    text = ''
      keyfile=${lib.escapeShellArg (toString cfg.zAiApiKeyFile)}
      if [ ! -r "$keyfile" ]; then
        echo "zcodex: z.ai API key not readable at $keyfile" >&2
        echo "zcodex: ensure sops-nix is active and the providers/z-ai/apiKey secret is configured." >&2
        exit 1
      fi

      export OPENAI_API_KEY="$(cat "$keyfile")"
      export OPENAI_BASE_URL="https://api.z.ai/api/coding/paas/v4"

      exec ${pkgs.codex}/bin/codex "$@"
    '';
  };
in
{
  options.modules.home.terminal.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration";

    opencodeGoApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing an OpenCode Go API key (e.g. a
        sops-nix decrypted secret path such as
        config.sops.secrets."providers/opencode-go/apiKey".path).

        When set, an `ocodex` wrapper is added to the environment that launches
        the Codex CLI against OpenCode Go's OpenAI-compatible endpoint.
      '';
    };

    zAiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing a z.ai API key (e.g. a sops-nix
        decrypted secret path such as
        config.sops.secrets."providers/z-ai/apiKey".path).

        When set, a `zcodex` wrapper is added to the environment that launches
        the Codex CLI against z.ai's OpenAI-compatible endpoint (GLM Coding
        Plan).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional opencodeGoEnable ocodexPackage ++ lib.optional zAiEnable zcodexPackage;

    modules.home.scripts.codex-fr.enable = opencodeGoEnable || zAiEnable;
  };
}
