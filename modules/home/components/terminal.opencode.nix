{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.opencode;
in
{
  options.modules.home.terminal.opencode = {
    enable = lib.mkEnableOption "OpenCode AI assistant configuration";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = {
        share = "disabled";
        theme = "one-dark";
        default_agent = "plan";
      };
      description = "OpenCode configuration settings";
    };

    oh-my-opencode-slim = {
      preset = lib.mkOption {
        type = lib.types.str;
        default = "personal";
        description = "Agent model presets to use, currently defined are 'personal' and 'work'";
      };
    };

    context7ApiKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional Context7 API key. When set, exported as the
        CONTEXT7_API_KEY environment variable which the oh-my-openagent
        plugin reads to authenticate against the Context7 MCP.

        Host/user configurations that want Context7 authentication should
        supply this value (typically from secrets/secrets.nix).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Packages
    home.packages = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.isLinux [ pkgs.opencode ]) # Assumed installed through brew for Darwin due to security on work mac
      [
        pkgs.ripgrep
        pkgs.fd
        pkgs.eza
        pkgs.procs
        pkgs.sd
        pkgs.jq
        pkgs.yq
      ]
    ];

    # Environment variables consumed by oh-my-openagent's built-in MCPs.
    # Context7 reads CONTEXT7_API_KEY at runtime to attach a bearer token
    # to the remote MCP. See: src/mcp/context7.ts in code-yeongyu/oh-my-openagent.
    home.sessionVariables = lib.mkIf (cfg.context7ApiKey != null) {
      CONTEXT7_API_KEY = cfg.context7ApiKey;
    };

    # AI Agent Configuration
    home.file."~/.config/opencode/AGENTS.md" = {
      text = ''
        You are an intelligent CLI assistant running on a ${
          if pkgs.stdenv.isDarwin then "Darwin (macOS)" else "Linux"
        } host managed by Nix.

        # Environment & Shell
        - **Shell**: The user uses `fish`. ALWAYS generate fish-compatible commands if a command is intended to be run by the user. Shell scripts can use bash/sh syntax.
          - Use `(cmd)` for substitution, not `$(cmd)`.
          - Use `set -gx VAR val` for exports.
          - Use `and`/`or` for logic.
        - **Packages**:
          - If a tool is missing, suggest using `nix-shell -p <pkg>` or the comma wrapper `, <cmd>`.

        # Preferred Tools
        The following modern tools are available and preferred over their traditional counterparts:
        - **Search**: `rg` (ripgrep) instead of `grep`.
        - **Find**: `fd` instead of `find`.
        - **List**: `eza` instead of `ls`.
        - **Processes**: `procs` instead of `ps`.
        - **Text Replace**: `sd` instead of `sed`.
        - **Data**: `jq` for JSON, `yq` for YAML.

        # Safety & Consent
        - You must ask for explicit confirmation before:
          - Running any command that deletes, overwrites, or mutates data (e.g. `rm`, `dd`, `>` redirection, `git push --force`, `git reset --hard`, `kubectl apply`, etc.).
          - Pushing commits to any remote branch.
        - Preview destructive commands with `echo` first when feasible.
        - Use a directory local to the context you were opened in for temp files (e.g. `./.opencode/tmp`). Ensure that directory is included in the `.gitignore` file if part of a git repo.
      '';
    };

    # OpenCode Configuration
    home.file.".config/opencode/opencode.json".text = builtins.toJSON (
      {
        "$schema" = "https://opencode.ai/config.json";
        instructions = [
          ".github/copilot-instructions.md"
        ];
        plugin = [
          # "oh-my-opencode-slim"
          "oh-my-openagent"
        ];
        # Default to a cheap model for now
        model = "github-copilot/gpt-5-mini";
        mcp = {
          "atlassian-mcp" = {
            type = "remote";
            url = "https://mcp.atlassian.com/v1/mcp";
            oauth = { };
          };
        };
      }
      // cfg.settings
    );

    # oh-my-openagent plugin configuration
    # Maps agents and categories to models available through the GitHub Copilot subscription.
    # See: https://github.com/code-yeongyu/oh-my-openagent/blob/dev/docs/reference/configuration.md
    home.file.".config/opencode/oh-my-openagent.json".text = builtins.toJSON {
      "$schema" =
        "https://raw.githubusercontent.com/code-yeongyu/oh-my-openagent/dev/assets/oh-my-opencode.schema.json";

      # Per-agent model overrides. All models are pinned to github-copilot/*
      # so they consume the GitHub Copilot subscription rather than other providers.
      agents = {
        # Main orchestrator - Claude Opus is the strongest orchestration model
        sisyphus = {
          model = "github-copilot/claude-opus-4.6";
          fallback_models = [
            "github-copilot/gpt-5.4-mini"
            "github-copilot/claude-haiku-4.5"
            "github-copilot/gpt-5.4-nano"
          ];
        };

        # Autonomous deep worker - GPT-5.4 is tuned for end-to-end execution
        hephaestus = {
          model = "github-copilot/gpt-5.4";
          variant = "medium";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # Strategic planner - benefits from a strong reasoning model
        prometheus = {
          model = "github-copilot/claude-opus-4.6";
          fallback_models = [ "github-copilot/gpt-5.4" ];
        };

        # High-IQ read-only consultant for architecture/debugging
        oracle = {
          model = "github-copilot/gpt-5.4";
          variant = "high";
          fallback_models = [
            "github-copilot/claude-opus-4.6"
            "github-copilot/gemini-3.1-pro"
          ];
        };

        # Cheap, fast research/docs lookup agent
        librarian = {
          model = "github-copilot/claude-haiku-4.5";
          fallback_models = [
            "github-copilot/gpt-5.4-mini"
            "github-copilot/gemini-3-flash"
          ];
        };

        # Fast contextual codebase grep agent
        explore = {
          model = "github-copilot/grok-code-fast-1";
          fallback_models = [
            "github-copilot/claude-haiku-4.5"
            "github-copilot/gpt-5.4-mini"
          ];
        };

        # Multimodal/visual analysis - needs vision-capable model
        multimodal-looker = {
          model = "github-copilot/gpt-5.4";
          fallback_models = [ "github-copilot/gemini-3.1-pro" ];
        };

        # Pre-planning consultant - identifies ambiguities/failure points
        metis = {
          model = "github-copilot/claude-opus-4.6";
          fallback_models = [ "github-copilot/gpt-5.4" ];
        };

        # Plan critic - rigorous review needs a strong reasoning model
        momus = {
          model = "github-copilot/gpt-5.4";
          variant = "xhigh";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # General-purpose / Sisyphus-Junior helper agents
        atlas = {
          model = "github-copilot/claude-sonnet-4.6";
          fallback_models = [ "github-copilot/gpt-5.4-mini" ];
        };
        sisyphus-junior = {
          model = "github-copilot/claude-sonnet-4.6";
          fallback_models = [ "github-copilot/gpt-5.4-mini" ];
        };
      };

      # Category model mappings - drives the task() delegation tool.
      # Sisyphus picks a category, the harness picks the model.
      categories = {
        # Frontend / UI / UX - Gemini Pro is strongest at visual work
        visual-engineering = {
          model = "github-copilot/gemini-3.1-pro";
          variant = "high";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # Hardest logic/architecture problems
        ultrabrain = {
          model = "github-copilot/gpt-5.4";
          variant = "xhigh";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # Goal-oriented autonomous work, thorough research before action
        deep = {
          model = "github-copilot/gpt-5.4";
          variant = "medium";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # Creative / unconventional approaches
        artistry = {
          model = "github-copilot/gemini-3.1-pro";
          variant = "high";
          fallback_models = [ "github-copilot/claude-opus-4.6" ];
        };

        # Trivial single-file changes
        quick = {
          model = "github-copilot/gpt-5.4-mini";
          fallback_models = [
            "github-copilot/claude-haiku-4.5"
            "github-copilot/gpt-5.4-nano"
          ];
        };

        # Generic low-effort work
        unspecified-low = {
          model = "github-copilot/claude-sonnet-4.6";
          fallback_models = [ "github-copilot/gpt-5.4-mini" ];
        };

        # Generic high-effort work
        unspecified-high = {
          model = "github-copilot/claude-opus-4.6";
          variant = "max";
          fallback_models = [ "github-copilot/gpt-5.4" ];
        };

        # Documentation, prose, technical writing
        writing = {
          model = "github-copilot/gemini-3-flash";
          fallback_models = [ "github-copilot/claude-sonnet-4.6" ];
        };
      };

      # Auto-fallback to backup models on transient API errors
      runtime_fallback = {
        enabled = true;
        notify_on_fallback = true;
      };

      # Limit concurrency on the single Copilot provider so we don't get rate-limited
      background_task = {
        defaultConcurrency = 5;
        providerConcurrency = {
          github-copilot = 5;
        };
      };

      tmux = {
        enabled = true;
      };
    };

    # Default plugin configuration for oh-my-opencode-slim
    home.file.".config/opencode/oh-my-opencode-slim.json".text = builtins.toJSON ({
      preset = cfg.oh-my-opencode-slim.preset;
      setDefaultAgent = true;
      presets = {
        personal = {
          orchestrator = {
            model = "github-copilot/gpt-5.4";
            skills = [ "*" ];
            mcps = [ "websearch" ];
          };
          oracle = {
            model = "github-copilot/gpt-5.4";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          librarian = {
            model = "github-copilot/gpt-5.4-mini";
            variant = "low";
            skills = [ ];
            mcps = [
              "websearch"
              "context7"
              "grep_app"
            ];
          };
          explorer = {
            model = "zai-coding-plan/glm-5.1";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          designer = {
            model = "github-copilot/gemini-3.1-pro";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          fixer = {
            model = "zai-coding-plan/glm-5.1";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
        };
        work = {
          orchestrator = {
            model = "github-copilot/gpt-5.4";
            skills = [ "*" ];
            mcps = [ "websearch" ];
          };
          oracle = {
            model = "github-copilot/gpt-5.4";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          librarian = {
            model = "github-copilot/gpt-5.4-mini";
            variant = "low";
            skills = [ ];
            mcps = [
              "websearch"
              "context7"
              "grep_app"
              "atlassian-mcp"
            ];
          };
          explorer = {
            model = "github-copilot/gpt-5.4-mini";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          designer = {
            model = "github-copilot/gemini-3.1-pro";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
          fixer = {
            model = "github-copilot/gpt-5.4-mini";
            variant = "low";
            skills = [ ];
            mcps = [ ];
          };
        };
      };
      council = {
        master = {
          model = "github-copilot/claude-opus-4.6";
        };
        default_preset = cfg.oh-my-opencode-slim.preset;
        presets = {
          personal = {
            alpha = {
              model = "github-copilot/gpt-5.4-mini";
            };
            beta = {
              model = "github-copilot/gemini-3.1-pro";
            };
            gamma = {
              model = "github-copilot/gpt-5.3-codex";
            };
          };
          work = {
            alpha = {
              model = "github-copilot/gpt-5.4-mini";
            };
            beta = {
              model = "github-copilot/gemini-3.1-pro";
            };
            gamma = {
              model = "github-copilot/gpt-5.3-codex";
            };
          };
        };
      };
      tmux = {
        enabled = true;
        layout = "main-vertical";
        main_pane_size = 60;
      };
    });
  };
}
