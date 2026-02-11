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
  };

  config = lib.mkIf cfg.enable {
    # Packages
    home.packages = [
      pkgs.opencode
      pkgs.ripgrep
      pkgs.fd
      pkgs.eza
      pkgs.procs
      pkgs.sd
      pkgs.jq
      pkgs.yq
    ];

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
        plugin = [ "oh-my-opencode-slim" ];
        # Default to a cheap model for now
        model = "github-copilot/gpt-5-mini";
        # provider = {
        #   "nano-gpt" = {
        #     models = {
        #       "moonshotai/kimi-k2.5" = {
        #         id = "moonshotai/kimi-k2.5";
        #         name = "Kimi K2.5";
        #         family = "kimi";
        #         attachment = false;
        #         reasoning = false;
        #         tool_call = true;
        #         structured_output = true;
        #         temperature = true;
        #         modalities = { input = ["text"]; output = ["text"]; };
        #         open_weights = false;
        #         limit = {
        #           context = 262144;
        #           output = 65536;
        #         };
        #       };
        #       "moonshotai/kimi-k2.5:thinking" = {
        #         id = "moonshotai/kimi-k2.5:thinking";
        #         name = "Kimi K2.5 Thinking";
        #         family = "kimi-thinking";
        #         attachment = false;
        #         reasoning = true;
        #         tool_call = true;
        #         interleaved = { field = "reasoning_content"; };
        #         structured_output = true;
        #         temperature = true;
        #         modalities = { input = ["text"]; output = ["text"]; };
        #         open_weights = false;
        #         limit = {
        #           context = 262144;
        #           output = 65536;
        #         };
        #       };
        #     };
        #   };
        # };
      }
      // cfg.settings
    );

    # Default plugin configuration for oh-my-opencode-slim
    home.file.".config/opencode/oh-my-opencode-slim.json".text = builtins.toJSON (
      {
        preset = cfg.oh-my-opencode-slim.preset;
        presets = {
          personal = {
            orchestrator = { model = "github-copilot/gpt-5.2-codex"; skills = ["*"]; mcps = ["websearch"]; };
            oracle       = { model = "github-copilot/gpt-5.2-codex"; variant = "low"; skills = []; mcps = []; };
            librarian    = { model = "github-copilot/gpt-5.1-codex-mini"; variant = "low"; skills = []; mcps = ["websearch" "context7" "grep_app"]; };
            explorer     = { model = "zai-coding-plan/glm-4.7"; variant = "low"; skills = []; mcps = []; };
            designer     = { model = "github-copilot/gemini-3-flash-preview"; variant = "low"; skills = []; mcps = []; };
            fixer        = { model = "zai-coding-plan/glm-4.7"; variant = "low"; skills = []; mcps = []; };
          };
          work = {
            orchestrator = { model = "github-copilot/gpt-5.2-codex"; skills = ["*"]; mcps = ["websearch"]; };
            oracle       = { model = "github-copilot/gpt-5.2-codex"; variant = "low"; skills = []; mcps = []; };
            librarian    = { model = "github-copilot/gpt-5.1-codex-mini"; variant = "low"; skills = []; mcps = ["websearch" "context7" "grep_app"]; };
            explorer     = { model = "github-copilot/gpt-5.1-codex-mini"; variant = "low"; skills = []; mcps = []; };
            designer     = { model = "github-copilot/gemini-3-flash-preview"; variant = "low"; skills = []; mcps = []; };
            fixer        = { model = "github-copilot/gemini-3-flash-preview"; variant = "low"; skills = []; mcps = []; };
          };
        };
        tmux = { enabled = true; layout = "main-vertical"; main_pane_size = 60; };
      }
    );
  };
}
