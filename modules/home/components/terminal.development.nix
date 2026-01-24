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
    # OpenCode configuration
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




