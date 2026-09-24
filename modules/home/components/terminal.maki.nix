{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.terminal.maki;

  makiPackage = pkgs.writeShellApplication {
    name = "maki";
    text = ''
      ${lib.optionalString (cfg.providers.z-ai.apiKeyFile != null) ''
        keyfile=${lib.escapeShellArg (toString cfg.providers.z-ai.apiKeyFile)}
        if [ -r "$keyfile" ]; then
          ZHIPU_API_KEY="$(cat "$keyfile")"
          export ZHIPU_API_KEY
        fi
      ''}
      ${lib.optionalString (cfg.providers.opencode-go.apiKeyFile != null) ''
        keyfile=${lib.escapeShellArg (toString cfg.providers.opencode-go.apiKeyFile)}
        if [ -r "$keyfile" ]; then
          OPENCODE_API_KEY="$(cat "$keyfile")"
          export OPENCODE_API_KEY
        fi
      ''}
      exec ${pkgs.maki}/bin/maki "$@"
    '';
  };
in
{
  options.modules.home.terminal.maki = {
    enable = lib.mkEnableOption "maki (AI coding agent) CLI";

    providers = {
      z-ai.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding a z.ai API key, e.g.
          config.sops.secrets."providers/z-ai/apiKey".path.

          When set, `maki` starts with ZHIPU_API_KEY exported, so its "zai"
          provider is ready to select.
        '';
      };

      opencode-go.apiKeyFile = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        description = ''
          Path to a file holding an OpenCode Go API key, e.g.
          config.sops.secrets."providers/opencode-go/apiKey".path.

          When set, `maki` starts with OPENCODE_API_KEY exported, so its
          "opencode-go" and "opencode" (Zen) providers are ready to select.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ makiPackage ];
  };
}
