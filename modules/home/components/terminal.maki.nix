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
      ${lib.optionalString (cfg.zaiApiKeyFile != null) ''
        keyfile=${lib.escapeShellArg (toString cfg.zaiApiKeyFile)}
        if [ -r "$keyfile" ]; then
          ZHIPU_API_KEY="$(cat "$keyfile")"
          export ZHIPU_API_KEY
        fi
      ''}
      ${lib.optionalString (cfg.opencodeApiKeyFile != null) ''
        keyfile=${lib.escapeShellArg (toString cfg.opencodeApiKeyFile)}
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

    zaiApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing a z.ai API key (e.g. a sops-nix
        decrypted secret path such as
        config.sops.secrets."providers/z-ai/apiKey".path).

        When set, maki is launched with ZHIPU_API_KEY exported so its "zai"
        provider is pre-authenticated.
      '';
    };

    opencodeApiKeyFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Optional path to a file containing an OpenCode Go API key (e.g. a
        sops-nix decrypted secret path such as
        config.sops.secrets."providers/opencode-go/apiKey".path).

        When set, maki is launched with OPENCODE_API_KEY exported so its
        "opencode-go" and "opencode" (Zen) providers are pre-authenticated.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ makiPackage ];
  };
}
