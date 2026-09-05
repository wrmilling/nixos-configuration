{
  config,
  lib,
  pkgs,
  inputs,
  outputs,
  secrets,
  ...
}:
let
  sandboxLib = import ../../../lib/claude-sandbox.nix { inherit lib; };
in
{
  imports = [
    inputs.microvm.nixosModules.microvm
    inputs.home-manager.nixosModules.home-manager
  ];

  modules.nixos = {
    base.enable = true;
    filesystem.enable = true;
    sshd.enable = true;
    chrony.enable = true;
    k8sUtils.enable = true;
    development.enable = true;
  };

  networking.hostName = "sandbox";

  # microvm.nix masks nix-daemon without a writable store, which breaks
  # home-manager activation and any in-guest nix build.
  microvm.writableStoreOverlay = "/nix/.rw-store";
  nix.settings.auto-optimise-store = lib.mkForce false;

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.getty.autologinUser = "w4cbe";

  users.users.w4cbe = {
    uid = sandboxLib.guestUid;
    openssh.authorizedKeys.keys = [ secrets.sandbox.sshPublicKey ];
  };

  # Replace a stale socket left by a previous session so the forwarded
  # gpg-agent socket can bind on reconnect.
  services.openssh.settings.StreamLocalBindUnlink = true;

  # sshd binds the forwarded gpg-agent socket here; nothing else creates the
  # directory because no local gpg-agent runs in the guest.
  systemd.user.tmpfiles.rules = [ "d %t/gnupg 0700 - - -" ];

  # Paths in the shared store are unknown to the guest's Nix database until the
  # closure is registered. microvm.nix does this from boot.postBootCommands,
  # which is unordered against home-manager activation and its first
  # `nix-store --realise`. --load-db needs a local store; nix would otherwise
  # pick the daemon and refuse the command.
  systemd.services.register-store-closure = {
    description = "Register the shared store closure in the Nix database";
    wantedBy = [ "multi-user.target" ];
    before = [ "home-manager-w4cbe.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [[ "$(cat /proc/cmdline)" =~ regInfo=([^ ]*) ]]; then
        ${config.nix.package.out}/bin/nix-store --store local --load-db < "''${BASH_REMATCH[1]}"
      fi
    '';
  };

  systemd.services.home-manager-w4cbe = {
    after = [ "register-store-closure.service" ];
    requires = [ "register-store-closure.service" ];
  };

  environment.systemPackages = [
    pkgs.kubernetes-helm
    pkgs.yamllint
    pkgs.shellcheck
    pkgs.python3Packages.pyyaml
    pkgs.skopeo
    pkgs.crane
    pkgs.ssh-to-age
    pkgs.google-cloud-sdk
  ];

  home-manager = {
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs outputs secrets; };
    users.w4cbe = {
      imports = [
        ../../../modules/home/base.nix
        ../../../modules/home/claude-sandbox.nix
      ];
      modules.homeType.claudeSandbox.enable = true;
      home.stateVersion = "26.05";
      # modules/home/base.nix and home-manager's NixOS integration both set nix.package.
      nix.package = lib.mkForce pkgs.lix;

      # Autologin (services.getty.autologinUser) lands here on the local
      # console (e.g. the Mac's serial console) -- SSH sessions always have
      # $SSH_CONNECTION set, so they're unaffected.
      programs.fish.loginShellInit = ''
        if test -z "$SSH_CONNECTION"
          cd ~/workspace
          exec herdr
        end
      '';
    };
  };

  system.stateVersion = "26.05";
}
