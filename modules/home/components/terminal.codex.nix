{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.codex;

  zAiEnable = cfg.providers.z-ai.apiKeyFile != null;
  opencodeGoEnable = cfg.providers.opencode-go.apiKeyFile != null;

  mcpHelper = import ../../../lib/mcp-servers.nix {
    inherit pkgs lib;
    homeDir = config.home.homeDirectory;
  };

  # Codex only speaks the Responses API. A model outside `responsesModels`
  # is chat/completions-only and is reached through a per-invocation
  # codex-relay; `responsesModels = null` means the provider always needs it.
  mkCodexWrapper =
    {
      name,
      provider,
      providerName,
      upstream,
      envKey,
      apiKeyFile,
      defaultModel,
      responsesModels,
    }:
    pkgs.writeShellApplication {
      inherit name;
      runtimeInputs = [
        pkgs.codex
        pkgs.codex-relay
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.jq
      ];
      text = ''
        keyfile=${lib.escapeShellArg apiKeyFile}
        if [ ! -r "$keyfile" ]; then
          echo "${name}: ${providerName} API key not readable at $keyfile" >&2
          exit 1
        fi
        ${envKey}="$(cat "$keyfile")"
        export ${envKey}

        model=""
        resume_id=""
        prev=""
        for arg in "$@"; do
          case "$prev" in
            -m|--model) model="$arg" ;;
            resume) case "$arg" in -*) ;; *) resume_id="$arg" ;; esac ;;
          esac
          case "$arg" in
            --model=*) model="''${arg#--model=}" ;;
          esac
          prev="$arg"
        done

        # A resumed session keeps its model, which decides whether it needs the
        # relay -- unless it moves here from another provider, which lacks it.
        model_override=""
        if [ -z "$model" ] && [ -n "$resume_id" ]; then
          rollout=$(find "''${CODEX_HOME:-$HOME/.codex}/sessions" -name "rollout-*$resume_id.jsonl" 2>/dev/null | head -n 1 || true)
          if [ -n "$rollout" ]; then
            session_provider=$(jq -r 'select(.type == "session_meta") | .payload.model_provider // empty' "$rollout" 2>/dev/null | head -n 1 || true)
            if [ "$session_provider" = ${lib.escapeShellArg provider} ]; then
              model=$(jq -r 'select(.type == "turn_context") | .payload.model // empty' "$rollout" 2>/dev/null | tail -n 1 || true)
              model_override="$model"
            fi
          fi
        fi
        if [ -z "$model" ]; then
          model=${lib.escapeShellArg defaultModel}
          model_override="$model"
        fi

        ${
          if responsesModels == null then
            "relay=1"
          else
            ''
              case "$model" in
                ${lib.concatStringsSep "|" responsesModels}) relay=0 ;;
                *) relay=1 ;;
              esac
            ''
        }

        base_url=${lib.escapeShellArg upstream}
        if [ "$relay" -eq 1 ]; then
          state="''${XDG_STATE_HOME:-$HOME/.local/state}/codex-relay/${provider}"
          mkdir -p "$state"
          chmod 700 "$state"
          log=$(mktemp)
          CODEX_RELAY_API_KEY="''$${envKey}" codex-relay \
            --port 0 \
            --upstream ${lib.escapeShellArg upstream} \
            --history-store disk \
            --history-dir "$state" >"$log" 2>&1 &
          relay_pid=$!
          trap 'kill "$relay_pid" 2>/dev/null || true; rm -f "$log"' EXIT
          trap 'exit 130' INT TERM HUP

          port=""
          for _ in $(seq 100); do
            port=$(grep -oE 'listening on 127\.0\.0\.1:[0-9]+' "$log" | grep -oE '[0-9]+$' || true)
            [ -n "$port" ] && break
            if ! kill -0 "$relay_pid" 2>/dev/null; then
              echo "${name}: codex-relay exited early:" >&2
              cat "$log" >&2
              exit 1
            fi
            sleep 0.1
          done
          if [ -z "$port" ]; then
            echo "${name}: codex-relay did not start" >&2
            exit 1
          fi
          base_url="http://127.0.0.1:$port/v1"
        fi

        args=(
          -c 'model_provider="${provider}"'
          -c "model_providers.${provider}={name=\"${providerName}\", base_url=\"$base_url\", env_key=\"${envKey}\", wire_api=\"responses\"}"
        )
        if [ -n "$model_override" ]; then
          args+=(-c "model=\"$model_override\"")
        fi

        if [ "$relay" -eq 1 ]; then
          codex "''${args[@]}" "$@"
        else
          exec codex "''${args[@]}" "$@"
        fi
      '';
    };

  zcodexPackage = mkCodexWrapper {
    name = "zcodex";
    provider = "z-ai";
    providerName = "z.ai";
    upstream = "https://api.z.ai/api/coding/paas/v4";
    envKey = "Z_AI_API_KEY";
    apiKeyFile = toString cfg.providers.z-ai.apiKeyFile;
    defaultModel = "glm-5.3";
    responsesModels = null;
  };

  ocodexPackage = mkCodexWrapper {
    name = "ocodex";
    provider = "opencode-go";
    providerName = "OpenCode Go";
    upstream = "https://opencode.ai/zen/go/v1";
    envKey = "OPENCODE_GO_API_KEY";
    apiKeyFile = toString cfg.providers.opencode-go.apiKeyFile;
    defaultModel = "gpt-6-luna";
    responsesModels = [
      "gpt-6-luna"
      "gpt-5.6-luna"
      "grok-4.7"
      "grok-4.6"
      "grok-4.5"
      "muse-spark-1.3-contributor"
      "muse-spark-1.2-contributor"
    ];
  };
in
{
  options.modules.home.terminal.codex = {
    enable = lib.mkEnableOption "Codex CLI configuration";

    providers = {
      z-ai.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding a z.ai API key, e.g.
          config.sops.secrets."providers/z-ai/apiKey".path.

          When set, run `zcodex` to start Codex against the z.ai coding plan
          (GLM models, default glm-5.3; pick another with `-m`), or `zfr` to
          pick and resume a Codex or Claude Code session through it. z.ai only offers
          chat/completions, so every run goes through a local codex-relay.
        '';
      };

      opencode-go.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding an OpenCode Go API key, e.g.
          config.sops.secrets."providers/opencode-go/apiKey".path.

          When set, run `ocodex` to start Codex against OpenCode Go (default
          gpt-6-luna; pick another with `-m`, e.g. `ocodex -m kimi-k3`), or
          `ofr` to pick and resume a Codex or Claude Code session through it. Responses-API
          models (GPT Luna, Grok, Muse Spark) connect directly; chat-only
          models (GLM, Kimi, DeepSeek, ...) go through a local codex-relay.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional zAiEnable zcodexPackage ++ lib.optional opencodeGoEnable ocodexPackage;

    # Static MCP server config. Model providers are passed via -c at runtime,
    # which overrides anything in this file.
    home.file.".codex/config.toml".source = (pkgs.formats.toml { }).generate "codex-config.toml" {
      mcp_servers = mcpHelper.codex;
    };

    modules.home.scripts.zfr.enable = lib.mkIf zAiEnable true;
    modules.home.scripts.ofr.enable = lib.mkIf opencodeGoEnable true;
  };
}
