{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.claude-code;

  # Default MCP servers - mcp-nixos is available in nixpkgs
  defaultMcpServers = {
    mcp-nixos = {
      command = "${pkgs.mcp-nixos}/bin/mcp-nixos";
      args = [ ];
    };
  };

  defaultSettings = {
    permissions.defaultMode = "plan";
    permissions.allow = [
      # Modern CLI (preferred tools per AGENTS.md)
      "Bash(rg:*)"
      "Bash(fd:*)"
      "Bash(eza:*)"
      "Bash(jq:*)"
      "Bash(yq:*)"
      "Bash(procs:*)"

      # POSIX read-only
      "Bash(ls:*)"
      "Bash(cat:*)"
      "Bash(head:*)"
      "Bash(tail:*)"
      "Bash(wc:*)"
      "Bash(sort:*)"
      "Bash(uniq:*)"
      "Bash(grep:*)"
      "Bash(find:*)"
      "Bash(tree:*)"
      "Bash(file:*)"
      "Bash(stat:*)"
      "Bash(which:*)"
      "Bash(type:*)"
      "Bash(command -v:*)"
      "Bash(test:*)"
      "Bash(env)"
      "Bash(printenv:*)"

      # Read-only git
      "Bash(git status:*)"
      "Bash(git diff:*)"
      "Bash(git log:*)"
      "Bash(git show:*)"
      "Bash(git rev-parse:*)"
      "Bash(git remote -v)"
      "Bash(git remote get-url:*)"
      "Bash(git config --get:*)"
      "Bash(git config -l)"
      "Bash(git config --list)"
      "Bash(git ls-files:*)"
      "Bash(git ls-tree:*)"
      "Bash(git blame:*)"
      "Bash(git stash list)"
      "Bash(git stash show:*)"

      # Write git (requires explicit user instruction to commit/push)
      "Bash(git add:*)"
      "Bash(git commit:*)"
      "Bash(git push:*)"

      # Read-only nix
      "Bash(nix eval:*)"
      "Bash(nix flake show:*)"
      "Bash(nix flake metadata:*)"
      "Bash(nix-store --query:*)"
      "Bash(nix derivation show:*)"
      "Bash(nix path-info:*)"

      # Web
      "WebSearch"
      "WebFetch"

      # MCP — mcp-nixos read-only tools
      "mcp__mcp-nixos"
    ];
  };

  statuslinePackage = pkgs.writeShellApplication {
    name = "claude-statusline";
    runtimeInputs = with pkgs; [
      jq
      starship
      coreutils
      gawk
      findutils
    ];
    text = ''
      payload=$(cat)
      cwd=$(printf '%s' "$payload" | jq -r '.workspace.current_dir // .cwd // "."')
      pct=$(printf '%s' "$payload" | jq -r '.context_window.used_percentage // 0' | awk '{printf "%d", $1+0}')
      [ -z "$pct" ] && pct=0

      CLAUDE_MODEL=$(printf '%s' "$payload" | jq -r '.model.display_name // .model.id // ""')
      CLAUDE_OUTPUT_STYLE=$(printf '%s' "$payload" | jq -r '.output_style.name // ""')
      CLAUDE_VERSION=$(printf '%s' "$payload" | jq -r '.version // ""')
      export CLAUDE_MODEL CLAUDE_OUTPUT_STYLE CLAUDE_VERSION
      export CLAUDE_CTX_PCT="$pct"

      filled=$(( pct / 10 ))
      if [ "$filled" -gt 10 ]; then filled=10; fi
      empty=$(( 10 - filled ))
      bar=""
      i=0; while [ "$i" -lt "$filled" ]; do bar="''${bar}█"; i=$((i+1)); done
      i=0; while [ "$i" -lt "$empty"  ]; do bar="''${bar}░"; i=$((i+1)); done
      export CLAUDE_CTX_BAR="$bar"

      ctx_size=$(printf '%s' "$payload" | jq -r '.context_window.context_window_size // 0' | awk '{printf "%d", $1+0}')
      ctx_size_human=""
      if [ "$ctx_size" -ge 1000000 ]; then
        ctx_size_human=$(awk -v n="$ctx_size" 'BEGIN { v = n / 1000000; if (v == int(v)) printf "%dM", v; else printf "%.1fM", v }')
      elif [ "$ctx_size" -ge 1000 ]; then
        ctx_size_human=$(awk -v n="$ctx_size" 'BEGIN { printf "%dK", int(n / 1000 + 0.5) }')
      elif [ "$ctx_size" -gt 0 ]; then
        ctx_size_human="$ctx_size"
      fi
      CLAUDE_CTX_SIZE_SUFFIX=""
      [ -n "$ctx_size_human" ] && CLAUDE_CTX_SIZE_SUFFIX=" ($ctx_size_human)"
      export CLAUDE_CTX_SIZE_SUFFIX

      cost_usd=$(printf '%s' "$payload" | jq -r '.cost.total_cost_usd // 0' | awk '{printf "%.2f", $1+0}')
      export CLAUDE_COST_USD="$cost_usd"

      lim5h=$(printf '%s' "$payload" | jq -r '.rate_limits.five_hour.used_percentage // empty' | awk 'NF{printf "%d", $1+0}')
      lim7d=$(printf '%s' "$payload" | jq -r '.rate_limits.seven_day.used_percentage // empty' | awk 'NF{printf "%d", $1+0}')
      export CLAUDE_LIMIT_5H_PCT="$lim5h"
      export CLAUDE_LIMIT_7D_PCT="$lim7d"

      session_id=$(printf '%s' "$payload" | jq -r '.session_id // ""')
      agent_count=0
      count_file="/tmp/claude-subagents-$session_id.count"
      if [ -n "$session_id" ] && [ -f "$count_file" ] \
         && [ -n "$(find "$count_file" -mmin -1 2>/dev/null)" ]; then
        agent_count=$(cat "$count_file" 2>/dev/null || echo 0)
      fi
      export CLAUDE_AGENT_COUNT="$agent_count"

      cd "$cwd" 2>/dev/null || true
      STARSHIP_CONFIG="${config.home.homeDirectory}/.claude/starship.toml" exec starship prompt
    '';
  };

  subagentStatuslinePackage = pkgs.writeShellApplication {
    name = "claude-subagent-statusline";
    runtimeInputs = with pkgs; [
      jq
      coreutils
      gawk
      findutils
    ];
    text = ''
      payload=$(cat)
      session_id=$(printf '%s' "$payload" | jq -r '.session_id // ""')
      [ -z "$session_id" ] && exit 0

      # Try array mode first (documented: tasks[] with full list per render).
      count=$(printf '%s' "$payload" \
        | jq -r 'if (.tasks|type) == "array"
                 then [.tasks[] | select(.status != "completed"
                                      and .status != "done"
                                      and .status != "error"
                                      and .status != "cancelled")] | length
                 else empty end' 2>/dev/null || true)

      if [ -z "$count" ]; then
        # Per-row fallback: touch a marker file per task id, count fresh ones.
        task_id=$(printf '%s' "$payload" | jq -r '.id // .task.id // ""')
        dir="/tmp/claude-subagents-$session_id"
        mkdir -p "$dir"
        [ -n "$task_id" ] && : > "$dir/$task_id"
        count=$(find "$dir" -type f -mmin -0.1 2>/dev/null | wc -l | awk '{print $1}')
      fi

      out="/tmp/claude-subagents-$session_id.count"
      printf '%s' "$count" > "$out.tmp" && mv "$out.tmp" "$out"

      # Output label for the agent panel row.
      printf '%s' "$payload" | jq -r '.label // .name // ""'
    '';
  };

  starshipConfig = (pkgs.formats.toml { }).generate "claude-starship.toml" {
    add_newline = false;
    command_timeout = 500;
    format =
      "$directory$git_branch$git_status$nix_shell"
      + "\${custom.model}\${custom.output_style}\${custom.agents}\${custom.cost}"
      + "\${custom.ctx_low}\${custom.ctx_med}\${custom.ctx_high}"
      + "\${custom.limit_5h_low}\${custom.limit_5h_med}\${custom.limit_5h_high}"
      + "\${custom.limit_7d_low}\${custom.limit_7d_med}\${custom.limit_7d_high}";

    directory = {
      format = "[$path]($style) ";
      truncation_length = 3;
    };
    git_branch = {
      symbol = " ";
      format = "[$symbol$branch]($style) ";
    };
    git_status.format = "([\\[$all_status$ahead_behind\\]]($style) )";
    nix_shell = {
      symbol = " ";
      format = "[$symbol$state]($style) ";
    };

    custom = {
      model = {
        when = ''[ -n "$CLAUDE_MODEL" ]'';
        command = ''printf '%s' "$CLAUDE_MODEL"'';
        format = "[🤖 $output]($style) ";
        style = "bold cyan";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      output_style = {
        when = ''[ -n "$CLAUDE_OUTPUT_STYLE" ] && [ "$CLAUDE_OUTPUT_STYLE" != "default" ]'';
        command = ''printf '%s' "$CLAUDE_OUTPUT_STYLE"'';
        format = "[$output]($style) ";
        style = "italic yellow";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      agents = {
        when = ''[ "$CLAUDE_AGENT_COUNT" -gt 0 ]'';
        command = ''printf '⚙ %s' "$CLAUDE_AGENT_COUNT"'';
        format = "[$output]($style) ";
        style = "bold magenta";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      cost = {
        when = ''awk "BEGIN{exit !($CLAUDE_COST_USD > 0)}"'';
        command = ''printf '$%s' "$CLAUDE_COST_USD"'';
        format = "[$output]($style) ";
        style = "bold green";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      ctx_low = {
        when = ''[ "$CLAUDE_CTX_PCT" -lt 50 ]'';
        command = ''printf 'ctx %s %s%%%s' "$CLAUDE_CTX_BAR" "$CLAUDE_CTX_PCT" "$CLAUDE_CTX_SIZE_SUFFIX"'';
        format = "[$output]($style)";
        style = "green";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      ctx_med = {
        when = ''[ "$CLAUDE_CTX_PCT" -ge 50 ] && [ "$CLAUDE_CTX_PCT" -lt 80 ]'';
        command = ''printf 'ctx %s %s%%%s' "$CLAUDE_CTX_BAR" "$CLAUDE_CTX_PCT" "$CLAUDE_CTX_SIZE_SUFFIX"'';
        format = "[$output]($style)";
        style = "yellow";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      ctx_high = {
        when = ''[ "$CLAUDE_CTX_PCT" -ge 80 ]'';
        command = ''printf 'ctx %s %s%%%s' "$CLAUDE_CTX_BAR" "$CLAUDE_CTX_PCT" "$CLAUDE_CTX_SIZE_SUFFIX"'';
        format = "[$output]($style)";
        style = "bold red";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_5h_low = {
        when = ''[ -n "$CLAUDE_LIMIT_5H_PCT" ] && [ "$CLAUDE_LIMIT_5H_PCT" -lt 50 ]'';
        command = ''printf '5h %s%%' "$CLAUDE_LIMIT_5H_PCT"'';
        format = "[ $output]($style)";
        style = "green";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_5h_med = {
        when = ''[ -n "$CLAUDE_LIMIT_5H_PCT" ] && [ "$CLAUDE_LIMIT_5H_PCT" -ge 50 ] && [ "$CLAUDE_LIMIT_5H_PCT" -lt 80 ]'';
        command = ''printf '5h %s%%' "$CLAUDE_LIMIT_5H_PCT"'';
        format = "[ $output]($style)";
        style = "yellow";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_5h_high = {
        when = ''[ -n "$CLAUDE_LIMIT_5H_PCT" ] && [ "$CLAUDE_LIMIT_5H_PCT" -ge 80 ]'';
        command = ''printf '5h %s%%' "$CLAUDE_LIMIT_5H_PCT"'';
        format = "[ $output]($style)";
        style = "bold red";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_7d_low = {
        when = ''[ -n "$CLAUDE_LIMIT_7D_PCT" ] && [ "$CLAUDE_LIMIT_7D_PCT" -lt 50 ]'';
        command = ''printf '7d %s%%' "$CLAUDE_LIMIT_7D_PCT"'';
        format = "[ $output]($style)";
        style = "green";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_7d_med = {
        when = ''[ -n "$CLAUDE_LIMIT_7D_PCT" ] && [ "$CLAUDE_LIMIT_7D_PCT" -ge 50 ] && [ "$CLAUDE_LIMIT_7D_PCT" -lt 80 ]'';
        command = ''printf '7d %s%%' "$CLAUDE_LIMIT_7D_PCT"'';
        format = "[ $output]($style)";
        style = "yellow";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
      limit_7d_high = {
        when = ''[ -n "$CLAUDE_LIMIT_7D_PCT" ] && [ "$CLAUDE_LIMIT_7D_PCT" -ge 80 ]'';
        command = ''printf '7d %s%%' "$CLAUDE_LIMIT_7D_PCT"'';
        format = "[ $output]($style)";
        style = "bold red";
        shell = [
          "bash"
          "--noprofile"
          "--norc"
        ];
      };
    };
  };
  # zclaude: launches Claude Code against z.ai's Anthropic-compatible endpoint
  # using GLM models. The z.ai API key is read from its sops-decrypted file at
  # runtime so the plaintext never enters the world-readable Nix store.
  # See: https://docs.z.ai/devpack/tool/claude
  zaiClaudePackage = pkgs.writeShellApplication {
    name = "zclaude";
    runtimeInputs = [
      pkgs.claude-code
      pkgs.coreutils
    ];
    text = ''
      keyfile=${lib.escapeShellArg (toString cfg.zaiApiKeyFile)}
      if [ ! -r "$keyfile" ]; then
        echo "zclaude: z.ai API key not readable at $keyfile" >&2
        echo "zclaude: ensure sops-nix is active and the providers/z-ai/apiKey secret is configured." >&2
        exit 1
      fi

      ANTHROPIC_AUTH_TOKEN="$(cat "$keyfile")"
      export ANTHROPIC_AUTH_TOKEN
      export ANTHROPIC_BASE_URL="https://api.z.ai/api/anthropic"
      export API_TIMEOUT_MS="3000000"
      export ANTHROPIC_DEFAULT_OPUS_MODEL="glm-5.2[1m]"
      export ANTHROPIC_DEFAULT_SONNET_MODEL="glm-4.7"
      export ANTHROPIC_DEFAULT_HAIKU_MODEL="glm-4.5-air"
      # Override the global subagent model (set to a Claude id below) with a
      # valid z.ai model so subagents stay on GLM when launched via zclaude.
      export CLAUDE_CODE_SUBAGENT_MODEL="glm-4.5-air"

      exec claude "$@"
    '';
  };
in
{
  options.modules.home.terminal.claude-code = {
    enable = lib.mkEnableOption "Claude Code CLI configuration";

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = defaultSettings;
      description = ''
        Contents of ~/.claude/settings.json. Defaults enable plan mode and a
        read-only command allowlist. Per-host modules can override individual
        fields with lib.mkForce.
      '';
    };

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = defaultMcpServers;
      description = ''
        MCP servers written to ~/.claude/claude_desktop_config.json via the
        home-manager programs.claude-code module. Stdio servers need
        {command, args}; HTTP servers need {type="http", url}.
      '';
    };

    extraMcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = ''
        Per-host MCP servers merged on top of mcpServers. Lets a single host
        add extra servers without redefining the shared defaults.
      '';
    };

    extraPermissions = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Per-host permission strings appended to the default allow list in
        settings.json. Lets a host add MCP or Bash permissions without
        redefining the full defaults.
      '';
    };

    statusline = {
      enable = lib.mkEnableOption "starship-driven Claude statusline" // {
        default = true;
      };
    };

    zaiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing a z.ai API key (e.g. a sops-nix
        decrypted secret path such as
        config.sops.secrets."providers/z-ai/apiKey".path).

        When set, a `zclaude` wrapper is added to the environment that launches
        Claude Code against z.ai's Anthropic-compatible endpoint using GLM
        models. The key is read from this file at runtime so the plaintext
        never lands in the world-readable Nix store.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.sessionVariables = {
      CLAUDE_CODE_SUBAGENT_MODEL = "claude-haiku-4-5";
    };

    # Provide the `zclaude` wrapper when a z.ai API key file is configured.
    home.packages = lib.optional (cfg.zaiApiKeyFile != null) zaiClaudePackage;

    programs.claude-code = {
      enable = true;
      # Package provided via the sadjow/claude-code-nix overlay (keeps in sync
      # with upstream releases without needing nixpkgs PRs).
      package = pkgs.claude-code;

      settings =
        cfg.settings
        // {
          permissions = cfg.settings.permissions // {
            allow = cfg.settings.permissions.allow ++ cfg.extraPermissions;
          };
        }
        // lib.optionalAttrs cfg.statusline.enable {
          statusLine = {
            type = "command";
            command = "${config.home.homeDirectory}/.claude/statusline-command.sh";
            padding = 0;
          };
          subagentStatusLine = {
            type = "command";
            command = "${config.home.homeDirectory}/.claude/subagent-statusline.sh";
            padding = 0;
          };
        };

      mcpServers = cfg.mcpServers // cfg.extraMcpServers;
    };

    home.file.".claude/statusline-command.sh" = lib.mkIf cfg.statusline.enable {
      source = "${statuslinePackage}/bin/claude-statusline";
      executable = true;
    };

    home.file.".claude/subagent-statusline.sh" = lib.mkIf cfg.statusline.enable {
      source = "${subagentStatuslinePackage}/bin/claude-subagent-statusline";
      executable = true;
    };

    home.file.".claude/starship.toml" = lib.mkIf cfg.statusline.enable {
      source = starshipConfig;
    };
  };
}
