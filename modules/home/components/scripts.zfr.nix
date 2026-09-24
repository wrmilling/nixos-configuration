{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.zfr;
  mkResumePicker = import ../../../lib/resume-picker.nix { inherit pkgs lib; };
in
{
  options.modules.home.scripts.zfr = {
    enable = lib.mkEnableOption "zfr - resume Claude Code and Codex sessions via zclaude/zcodex";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (mkResumePicker {
        name = "zfr";
        launchers = {
          claude = "zclaude";
          codex = "zcodex";
        };
        description = "Pick a Claude Code or Codex session and resume it on z.ai.";
        enableHint = "modules.home.terminal.{claude-code,codex}.providers.z-ai.apiKeyFile";
      })
    ];
  };
}
