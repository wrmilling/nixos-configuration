{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.homeType.personal;
  sandboxLib = import ../../lib/agent-sandbox.nix { inherit lib; };
in
{
  options.modules.homeType.personal = {
    enable = lib.mkEnableOption "personal home-manager modules";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."providers/z-ai/apiKey" = {
      sopsFile = ../../secrets/agents.yaml;
    };

    sops.secrets.${sandboxLib.sshSecretName} = {
      sopsFile = ../../secrets/agents.yaml;
      mode = "0400";
    };

    # Read-only in-cluster credential for the agent sandbox (k3s-gitops:kube-system/agent-readonly).
    sops.secrets."sandbox/kubeconfig" = {
      sopsFile = ../../secrets/agents.yaml;
      mode = "0400";
    };

    # sops-nix's `path` is always a symlink into a per-generation runtime
    # directory, which virtiofs shares as a dangling symlink in the guest
    # (the target only means something on the host). Copy the real,
    # dereferenced bytes to the fixed path the sandbox's extraShares mounts
    # as ~/.kube instead.
    home.activation.agentSandboxKubeconfig = lib.hm.dag.entryAfter [ "sops-nix" ] ''
      run ${pkgs.coreutils}/bin/install -Dm0400 \
        ${config.sops.secrets."sandbox/kubeconfig".path} \
        "/home/w4cbe/.config/agent-sandbox/kube/config"
    '';

    modules = {
      home.base.enable = true;
      home.sops.enable = true;
      home.terminal.atuin.enable = true;
      home.terminal.claude-code.enable = true;
      home.terminal.claude-code.zclaude.apiKeyFile = config.sops.secrets."providers/z-ai/apiKey".path;
      home.terminal.development.enable = true;
      home.terminal.fish.enable = true;
      home.terminal.general.enable = true;
      home.terminal.git.enable = true;
      home.terminal.gpg.enable = true;
      home.terminal.k8s-utils.enable = true;
      home.terminal.starship.enable = true;
      home.terminal.tmux.enable = true;
      home.terminal.vim.enable = true;
      home.graphical.alacritty.enable = true;
      home.graphical.discord.enable = true;
      home.graphical.firefox.enable = true;
      # home.graphical.keybase.enable = true;
      home.graphical.minecraft-client.enable = true;
      home.graphical.obsidian.enable = true;
      home.graphical.obsidian.vaults.personal.enable = true;
      home.graphical.xresources.enable = true;
    };

    home.packages = lib.mkMerge [
      (lib.mkIf pkgs.stdenv.hostPlatform.isx86_64 [ pkgs.slack ])
      (lib.mkIf pkgs.stdenv.hostPlatform.isAarch64 [ ])
      [
        pkgs.claude-desktop
        pkgs.element-desktop
        pkgs.signal-desktop
        pkgs.gomuks-desktop
        pkgs.gparted
        pkgs.keepassxc
        pkgs.vlc
        pkgs.hugo
        pkgs.libreoffice
        pkgs.chromium # Will not run from nix-shell for some reason
        pkgs.calibre
        pkgs.deskflow
      ]
    ];
  };
}
