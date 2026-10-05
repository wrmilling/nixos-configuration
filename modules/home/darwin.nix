{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.darwin;
  sandboxLib = import ../../lib/agent-sandbox.nix { inherit lib; };
in
{
  options.modules.homeType.darwin = {
    enable = lib.mkEnableOption "darwin home-manager modules";

    agentSandboxSessionSync.device = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Decrypt this sandbox device's Syncthing identity and the work folder
        password, which modules/darwin/agent-sandbox.nix copies into the guest.
        Must match that module's sessionSync.device.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = {
      # Login key for the local agent sandbox, so starting it needs no smartcard
      # touch. modules/darwin/agent-sandbox.nix reads it back via
      # sandboxLib.sshIdentityFile.
      ${sandboxLib.sshSecretName} = {
        sopsFile = ../../secrets/agents.yaml;
        mode = "0400";
      };
    }
    // lib.optionalAttrs (cfg.agentSandboxSessionSync.device != null) (
      lib.mapAttrs' (
        file: key:
        lib.nameValuePair (sandboxLib.sessionSync.secretName file) {
          sopsFile = ../../secrets/agent-sandbox-work.yaml;
          inherit key;
          mode = "0400";
        }
      ) (sandboxLib.sessionSync.secretKeys cfg.agentSandboxSessionSync.device)
    );

    # Host-only; the shared workspace's .codegraph is guest-writable.
    home.sessionVariables.CODEGRAPH_NO_PROMPT_HOOK = "1";

    modules = {
      home.base.enable = true;
      home.sops.enable = true;
      home.graphical.alacritty.enable = true;
      home.graphical.obsidian.enable = true;
      home.graphical.obsidian.vaults.work.enable = true;
      home.graphical.xresources.enable = true;
      home.terminal.atuin.enable = true;
      home.terminal.claude-code.enable = true;
      home.terminal.development.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.general.enable = true;
      home.terminal.git.enable = true;
      home.terminal.gpg.darwin.enable = true;
      home.terminal.k8s-utils.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.tmux.enable = true;
      home.terminal.vim.enable = true;
    };

    programs.obsidian.defaultSettings.app = {
      readableLineLength = true;
      showLineNumber = true;
      tabSize = 2;
    };

    home.packages = [
      pkgs.cloudfoundry-cli
      pkgs.rancher
      pkgs.shiftleft-sl
      pkgs.wizcli
      pkgs.slides-git
      pkgs.graph-easy
    ];
  };
}
