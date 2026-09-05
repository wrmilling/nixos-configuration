{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.homeType.claudeSandbox;
in
{
  options.modules.homeType.claudeSandbox = {
    enable = lib.mkEnableOption "Claude Code microVM guest home-manager modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      home.base.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.general.enable = true;
      home.terminal.git.enable = true;
      home.terminal.gpg.enable = true;
      home.terminal.k8s-utils.enable = true;
      home.terminal.development.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.vim.enable = true;
      home.terminal.claude-code.enable = true;
    };

    # gpg uses the agent socket forwarded from the host, which holds the
    # smartcard. A local agent would bind that path first.
    services.gpg-agent.enable = lib.mkForce false;
  };
}
