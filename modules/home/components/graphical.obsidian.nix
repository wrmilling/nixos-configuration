{
  config,
  lib,
  pkgs,
  secrets,
  ...
}:
let
  cfg = config.modules.home.graphical.obsidian;

  localRestApiDirs = map (
    vault: "${config.home.homeDirectory}/${vault.target}/.obsidian/plugins/obsidian-local-rest-api"
  ) (builtins.filter (vault: vault.enable) (builtins.attrValues config.programs.obsidian.vaults));
in
{
  options.modules.home.graphical.obsidian = {
    enable = lib.mkEnableOption "obsidian packages / settings";

    vaults = {
      personal.enable = lib.mkEnableOption "personal obsidian vault at ~/.obsidian/personal";
      work.enable = lib.mkEnableOption "work obsidian vault at ~/.obsidian/work";
    };

    plugins.localRestApi.enable = lib.mkEnableOption "Local REST API with MCP community plugin";
  };

  config = lib.mkIf cfg.enable {
    # Required by the pandoc community plugin, which shells out to it.
    home.packages = [ pkgs.pandoc ];

    sops.secrets = lib.mkIf cfg.plugins.localRestApi.enable {
      "local-rest-api/cert".sopsFile = ../../../secrets/obsidian.yaml;
      "local-rest-api/privateKey".sopsFile = ../../../secrets/obsidian.yaml;
      "local-rest-api/apiKey".sopsFile = ../../../secrets/obsidian.yaml;
    };

    # The plugin only reads its cert and API key from data.json, which it also writes to,
    # so merge ours in rather than linking a read-only file. No CA key means no auto-renewal.
    home.activation.obsidianLocalRestApi = lib.mkIf cfg.plugins.localRestApi.enable (
      lib.hm.dag.entryAfter [ "linkGeneration" "sops-nix" ] ''
        cert=${config.sops.secrets."local-rest-api/cert".path}
        privateKey=${config.sops.secrets."local-rest-api/privateKey".path}
        apiKey=${config.sops.secrets."local-rest-api/apiKey".path}
        if [[ -r $cert && -r $privateKey && -r $apiKey ]]; then
          jqArgs=(--rawfile cert "$cert" --rawfile privateKey "$privateKey" --rawfile apiKey "$apiKey")
          filter='.crypto = {$cert, $privateKey} | .apiKey = ($apiKey | rtrimstr("\n"))'
          for dir in ${lib.escapeShellArgs localRestApiDirs}; do
            data="$dir/data.json"
            current='{}'
            if [[ -s $data ]]; then current=$(cat "$data"); fi
            if ! ${lib.getExe pkgs.jq} -e "''${jqArgs[@]}" "($filter) == ." <<<"$current" >/dev/null; then
              tmp=$(mktemp)
              ${lib.getExe pkgs.jq} "''${jqArgs[@]}" "$filter" <<<"$current" >"$tmp"
              run mkdir -p "$dir"
              run install -m 0600 "$tmp" "$data"
              rm -f "$tmp"
              noteEcho "Updated Local REST API cert/API key in $data; restart Obsidian to load them"
            fi
            if [[ -e $data ]]; then run chmod 0600 "$data"; fi
          done
        else
          warnEcho "Local REST API secrets not decrypted yet; skipping (re-run activation)"
        fi
      ''
    );

    modules.home.terminal.claude-code.extraMcpServers = lib.mkIf cfg.plugins.localRestApi.enable {
      obsidian = {
        type = "http";
        url = "https://localhost.${secrets.hosts.common.domain}:27124/mcp/";
        headersHelper = toString (
          pkgs.writeShellScript "obsidian-mcp-headers" ''
            exec ${lib.getExe pkgs.jq} -n --rawfile key ${config.sops.secrets."local-rest-api/apiKey".path} \
              '{Authorization: "Bearer \($key | rtrimstr("\n"))"}'
          ''
        );
      };
    };

    programs.obsidian = {
      enable = true;
      package = pkgs.obsidian;

      defaultSettings.communityPlugins = [
        { pkg = pkgs.obsidianPlugins.pandoc; }
        { pkg = pkgs.obsidianPlugins.dataview; }
        { pkg = pkgs.obsidianPlugins.advanced-tables; }
        { pkg = pkgs.obsidianPlugins.tasks; }
        { pkg = pkgs.obsidianPlugins.tasknotes; }
      ]
      ++ lib.optional cfg.plugins.localRestApi.enable { pkg = pkgs.obsidianPlugins.local-rest-api; };

      # defaultSettings.cssSnippets = [
      #   { source = ./assets/tasknotes-kanban.css; }
      # ];

      vaults = lib.mkMerge [
        (lib.mkIf cfg.vaults.personal.enable {
          personal.target = ".obsidian/personal";
        })
        (lib.mkIf cfg.vaults.work.enable {
          work.target = ".obsidian/work";
        })
      ];
    };
  };
}
