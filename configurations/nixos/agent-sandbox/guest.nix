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
  sandboxLib = import ../../../lib/agent-sandbox.nix { inherit lib; };
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
    development = {
      enable = true;
      graphical.enable = false;
    };
  };

  networking.hostName = "sandbox";
  # IPv4-only guest; drops the vmnet ULA that would otherwise re-expose port 22.
  networking.enableIPv6 = false;
  boot.kernelParams = [ "ipv6.disable=1" ];

  # microvm.nix masks nix-daemon without a writable store, which breaks
  # home-manager activation and any in-guest nix build.
  microvm.writableStoreOverlay = "/nix/.rw-store";
  nix.settings = {
    auto-optimise-store = lib.mkForce false;
    trusted-users = lib.mkForce [ "root" ];
  };

  # Automatic, since nobody's around to type the guest's sudo password for
  # the interactive `ncl` abbreviation. Only reclaims the writable overlay
  # (guest-local builds/generations) -- the shared read-only store is the
  # host's to collect.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "-d";
  };

  boot.kernelPackages = pkgs.linuxPackages_latest;

  services.getty.autologinUser = "w4cbe";

  users.users.w4cbe = {
    uid = sandboxLib.guestUid;
    openssh.authorizedKeys.keys = lib.mkForce [ secrets.sandbox.sshPublicKey ];
  };

  # Replace a stale socket left by a previous session so the forwarded
  # gpg-agent socket can bind on reconnect.
  services.openssh.settings.StreamLocalBindUnlink = true;

  # sshd binds the forwarded gpg-agent sockets here; nothing else creates the
  # directory because no local gpg-agent runs in the guest.
  systemd.user.tmpfiles.rules = [ "d %t/gnupg 0700 - - -" ];

  # Disable services not needed within guest
  services.fail2ban.enable = lib.mkForce false;
  services.rpcbind.enable = lib.mkForce false;
  services.resolved = {
    settings.Resolve = {
      LLMNR = "false";
      MulticastDNS = "false";
    };
  };

  # Points at the forwarded ssh-support socket (RemoteForward, host side), so
  # git push/pull in the guest authenticate with the host's YubiKey. Derived
  # from the user's actual uid rather than sandboxLib's pinned one, since the
  # Darwin host has to renumber the guest user to match its own account.
  environment.variables.SSH_AUTH_SOCK = "/run/user/${toString config.users.users.w4cbe.uid}/gnupg/S.gpg-agent.ssh";

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
        ../../../modules/home/agent-sandbox.nix
      ];
      modules.homeType.agentSandbox.enable = true;
      home.stateVersion = "26.05";
      # modules/home/base.nix and home-manager's NixOS integration both set nix.package.
      nix.package = lib.mkForce pkgs.lix;

      # Autologin (services.getty.autologinUser) lands here on the local
      # console (e.g. the Mac's serial console) -- SSH sessions always have
      # $SSH_CONNECTION set, so they're unaffected.
      programs.fish.loginShellInit = ''
        if test -z "$SSH_CONNECTION"
          exec herdr
        end
      '';
    };
  };

  system.stateVersion = "26.05";
}
