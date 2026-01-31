{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.development;

  # Prefer Node.js 22 if available (required by Copilot CLI), fall back otherwise
  node = if pkgs ? nodejs_22 then pkgs.nodejs_22 else (pkgs.nodejs_latest or pkgs.nodejs);

  copilot = pkgs.writeShellScriptBin "copilot" ''
    #!${pkgs.bash}/bin/bash
    # Run GitHub Copilot CLI via npx so we don't need a separate package.
    # Requires network on first run to download @github/copilot.
    exec ${node}/bin/npx --yes @github/copilot "$@"
  '';
in
{
  options.modules.home.terminal.development = {
    enable = lib.mkEnableOption "development configuration file settings";

    opencode = {
      settings = lib.mkOption {
        type = lib.types.attrs;
        default = {
          share = "disabled";
          theme = "one-dark";
          default_agent = "plan";
        };
        description = "OpenCode configuration settings";
      };
    };

    oh-my-opencode-slim  = {
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
      node
      copilot
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
      }
      // cfg.opencode.settings
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
