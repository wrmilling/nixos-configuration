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
        mcp = {
          "atlassian-mcp" = {
            type = "remote";
            url = "https://mcp.atlassian.com/v1/mcp";
            oauth = {};
          };
        };
      }
      // cfg.settings
    );

    # Default plugin configuration for oh-my-opencode-slim
    home.file.".config/opencode/oh-my-opencode-slim.json".text = builtins.toJSON (
      {
        preset = cfg.oh-my-opencode-slim.preset;
        setDefaultAgent = true;
        presets = {
          personal = {
            orchestrator = { model = "github-copilot/gpt-5.4"; skills = ["*"]; mcps = ["websearch"]; };
            oracle       = { model = "github-copilot/gpt-5.4"; variant = "low"; skills = []; mcps = []; };
            librarian    = { model = "github-copilot/gpt-5.4-mini"; variant = "low"; skills = []; mcps = ["websearch" "context7" "grep_app"]; };
            explorer     = { model = "zai-coding-plan/glm-5.1"; variant = "low"; skills = []; mcps = []; };
            designer     = { model = "github-copilot/gemini-3.1-pro-preview"; variant = "low"; skills = []; mcps = []; };
            fixer        = { model = "zai-coding-plan/glm-5.1"; variant = "low"; skills = []; mcps = []; };
            council      = {
              master       = { model = "github-copilot/claude-opus-4.6" };
              presets      = {
                default      = {
                  alpha        = { model = "github-copilot/gpt-5.4-mini" };
                  beta         = { model = "github-copilot/gemini-3.1-pro-preview" };
                  gamma        = { model = "github-copilot/gpt-5.3-codex" };
                };
              };
            };
          };
          work = {
            orchestrator = { model = "github-copilot/gpt-5.4"; skills = ["*"]; mcps = ["websearch"]; };
            oracle       = { model = "github-copilot/gpt-5.4"; variant = "low"; skills = []; mcps = []; };
            librarian    = { model = "github-copilot/gpt-5.4-mini"; variant = "low"; skills = []; mcps = ["websearch" "context7" "grep_app" "atlassian-mcp"]; };
            explorer     = { model = "github-copilot/gpt-5.4-mini"; variant = "low"; skills = []; mcps = []; };
            designer     = { model = "github-copilot/gemini-3.1-pro-preview"; variant = "low"; skills = []; mcps = []; };
            fixer        = { model = "github-copilot/gpt-5.4-mini"; variant = "low"; skills = []; mcps = []; };
            council      = {
              master       = { model = "github-copilot/claude-opus-4.6" };
              presets      = {
                default      = {
                  alpha        = { model = "github-copilot/gpt-5.4-mini" };
                  beta         = { model = "github-copilot/gemini-3.1-pro-preview" };
                  gamma        = { model = "github-copilot/gpt-5.3-codex" };
                };
              };
            };
          };
        };
        tmux = { enabled = true; layout = "main-vertical"; main_pane_size = 60; };
      }
    );
  };
}
