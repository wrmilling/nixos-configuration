{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.development;
in
{
  options.modules.home.terminal.development = {
    enable = lib.mkEnableOption "development configuration file settings";
  };

  config = lib.mkIf cfg.enable {
    # Packages
    home.packages = [
      pkgs.node
      pkgs.copilot
      pkgs.opencode
    ];

    # Copilot Configuration (shared with OpenCode)
    home.file.".copilot/copilot-instructions.md" = {
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
      '';
    };

    # OpenCode Configuration
    home.file.".config/opencode/opencode.json".text = builtins.toJSON (
      {
        "$schema" = "https://opencode.ai/config.json";
        instructions = [
          "~/.copilot/copilot-instructions.md"
          ".github/copilot-instructions.md"
        ];
        plugin = [
          "oh-my-opencode"
        ];
      }
      // cfg.opencode.settings
    );
  };
}




