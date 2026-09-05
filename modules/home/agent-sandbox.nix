{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.agentSandbox;
in
{
  options.modules.homeType.agentSandbox = {
    enable = lib.mkEnableOption "agent sandbox guest home-manager modules";
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

    # Runs herdr as a supervised service instead of an ad-hoc ssh/console
    # foreground process, so systemd can run `herdr server stop` on guest
    # shutdown -- otherwise the VM powering off kills the server before it
    # can flush pane cwd state to session.json.
    systemd.user.services.herdr = {
      Unit.Description = "Herdr headless server";
      Install.WantedBy = [ "default.target" ];
      Service = {
        ExecStart = "${pkgs.herdr}/bin/herdr server";
        ExecStop = "${pkgs.herdr}/bin/herdr server stop";
        WorkingDirectory = "/home/w4cbe/workspace";
        Restart = "on-failure";
      };
    };
  };
}
