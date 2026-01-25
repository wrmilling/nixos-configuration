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
          # "oh-my-opencode"
        ];
        # Default to a cheap model for now
        model = "github-copilot/gpt-5-mini";
      }
      // cfg.opencode.settings
    );
  };
}




