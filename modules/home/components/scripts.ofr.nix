{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.home.scripts.ofr;
  mkResumePicker = import ../../../lib/resume-picker.nix { inherit pkgs lib; };
in
{
  options.modules.home.scripts.ofr = {
    enable = lib.mkEnableOption "ofr - resume Claude Code and Codex sessions via oclaude/ocodex";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      (mkResumePicker {
        name = "ofr";
        launchers = {
          claude = "oclaude";
          codex = "ocodex";
        };
        description = "Pick a Claude Code or Codex session and resume it on OpenCode Go.";
        enableHint = "modules.home.terminal.{claude-code,codex}.providers.opencode-go.apiKeyFile";
      })
    ];
  };
}
