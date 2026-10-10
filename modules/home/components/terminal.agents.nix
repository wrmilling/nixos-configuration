{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.agents;
  terminal = config.modules.home.terminal;
  homeDir = config.home.homeDirectory;

  anyHarness =
    terminal.claude-code.enable
    || terminal.codex.enable
    || terminal.opencode.enable
    || terminal.maki.enable;
  # Codex reads only ~/.agents/skills, Claude Code only ~/.claude/skills; OpenCode and maki read both.
  agentsDirHarnesses = terminal.codex.enable || terminal.opencode.enable || terminal.maki.enable;

  enabledServers = lib.filterAttrs (_: s: s.enable) cfg.mcpServers;
  enabledValues = lib.attrValues enabledServers;
  allSkills = cfg.skills // lib.mergeAttrsList (map (s: s.skills) enabledValues);

  reaWithEngines = pkgs.symlinkJoin {
    name = "rea-with-engines";
    paths = [ pkgs.rea ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for bin in rea rea-agents; do
        wrapProgram $out/bin/$bin \
          --set-default GHIDRA_INSTALL_DIR ${pkgs.ghidra}/lib/ghidra \
          --set-default JAVA_HOME ${pkgs.openjdk21.home} \
          --set-default REA_JADX_MCP_JAR ${pkgs.rea.jadxMcpJar} \
          --set-default REA_PWNTOOLS_PYTHON ${pkgs.rea.pwntoolsPython}/bin/python3 \
          --set-default REA_BINWALK_COMMAND ${lib.getExe pkgs.binwalk} \
          --set-default REA_UNBLOB_COMMAND ${lib.getExe pkgs.unblob} \
          --set-default REA_FIRMWARE_PRLIMIT_COMMAND ${lib.getExe' pkgs.util-linux "prlimit"}
      done
    '';
    inherit (pkgs.rea) meta;
  };

  skillFiles =
    dir: lib.mapAttrs' (name: path: lib.nameValuePair "${dir}/${name}" { source = path; }) allSkills;

  serverType = lib.types.submodule {
    options = {
      enable = lib.mkEnableOption "this MCP server for every agent harness" // {
        default = true;
      };
      command = lib.mkOption { type = lib.types.str; };
      args = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
      };
      env = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
      };
      claudePermissions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Claude Code allow rules added while this server is enabled.";
      };
      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = [ ];
        description = "Packages put on PATH while this server is enabled, e.g. its CLI.";
      };
      sessionVariables = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        description = "Session variables set while this server is enabled, for CLI use outside the MCP server.";
      };
      skills = lib.mkOption {
        type = lib.types.attrsOf lib.types.path;
        default = { };
        description = "Skill directories installed while this server is enabled, keyed by skill name.";
      };
    };
  };
in
{
  options.modules.home.terminal.agents = {
    mcpServers = lib.mkOption {
      type = lib.types.attrsOf serverType;
      default = { };
      description = ''
        Local (stdio) MCP servers for every agent harness. lib/mcp-servers.nix
        projects the enabled ones into each harness's config shape.
      '';
    };

    skills = lib.mkOption {
      type = lib.types.attrsOf lib.types.path;
      default = { };
      description = ''
        Skill directories (each holding a SKILL.md) not tied to an MCP server,
        installed for every enabled agent harness, keyed by skill name.
      '';
    };
  };

  config = lib.mkMerge [
    {
      modules.home.terminal.agents.mcpServers = {
        "mcp-nixos" = {
          command = lib.getExe pkgs.mcp-nixos;
          claudePermissions = [
            "mcp__mcp-nixos"
            "mcp__plugin_claude-code-home-manager_mcp-nixos__nix"
          ];
        };

        kubernetes = {
          command = lib.getExe pkgs.kubernetes-mcp-server;
          args = [ "--read-only" ];
          env.KUBECONFIG = "${homeDir}/.kube/config";
          claudePermissions = map (tool: "mcp__kubernetes__${tool}") [
            "configuration_contexts_list"
            "configuration_view"
            "events_list"
            "namespaces_list"
            "nodes_log"
            "nodes_stats_summary"
            "nodes_top"
            "pods_get"
            "pods_list"
            "pods_list_in_namespace"
            "pods_log"
            "pods_top"
            "resources_get"
            "resources_list"
          ];
        };

        # --read-only is enforced at the server level.
        flux = {
          command = lib.getExe pkgs.flux-operator-mcp;
          args = [
            "serve"
            "--read-only"
          ];
          env.KUBECONFIG = "${homeDir}/.kube/config";
          claudePermissions = [ "mcp__flux" ];
        };

        codegraph = {
          command = lib.getExe pkgs.codegraph;
          args = [
            "serve"
            "--mcp"
          ];
          env.CODEGRAPH_TELEMETRY = "0";
          claudePermissions = [ "mcp__codegraph" ];
          packages = [ pkgs.codegraph ];
          # The CLI (`codegraph init`/`index`/`sync`) never goes through the MCP server's env.
          sessionVariables.CODEGRAPH_TELEMETRY = "0";
        };

        # Its own option, so only rea carries it: `mcpServers.rea.engines.enable`.
        rea =
          { config, ... }:
          let
            reaPackage = if config.engines.enable then reaWithEngines else pkgs.rea;
          in
          {
            options.engines.enable = lib.mkEnableOption ''
              the native-binary, Android APK and firmware engines (Ghidra, JADX,
              pwntools, Binwalk, Unblob). Without them rea only analyzes
              JavaScript and managed code.
            '';

            config = {
              enable = lib.mkDefault false;
              command = lib.getExe reaPackage;
              args = [ "mcp" ];
              claudePermissions = [ "mcp__rea" ];
              packages = [ reaPackage ];
              skills.reverse-engineer-anything = "${pkgs.rea}/lib/node_modules/rea-agents/skills/reverse-engineer-anything";
            };
          };
      };
    }

    (lib.mkIf anyHarness {
      home.packages = lib.concatMap (s: s.packages) enabledValues;
      home.sessionVariables = lib.mergeAttrsList (map (s: s.sessionVariables) enabledValues);
      home.file = lib.mkMerge [
        (lib.mkIf terminal.claude-code.enable (skillFiles ".claude/skills"))
        (lib.mkIf agentsDirHarnesses (skillFiles ".agents/skills"))
      ];
    })
  ];
}
