{
  config,
  lib,
  pkgs,
  utils,
  inputs,
  outputs,
  secrets,
  ...
}:
let
  sandboxLib = import ../../../lib/agent-sandbox.nix { inherit lib; };

  rootFs = config.fileSystems."/";
  # overlayfs forbids changing a layer under a live mount, hence the guard.
  # Flags rather than exits: inlined into stage 1, where exit would end it.
  sweepWhiteouts = root: ''
    storeMounted=
    while read -r _ _ _ _ mountPoint _; do
      if [ "$mountPoint" = "${root}/nix/store" ]; then storeMounted=1; fi
    done < /proc/self/mountinfo
    if [ -z "$storeMounted" ]; then
      for path in ${root}${config.microvm.writableStoreOverlay}/store/*; do
        if [ -c "$path" ]; then rm -f "$path"; fi
      done
    fi
  '';
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
    chrony = {
      enable = true;
      # A VM clock can be arbitrarily wrong at any time, not just first boot, and
      # the default 3 steps get exhausted on a multi-day offset.
      makestepLimit = 1000000;
    };
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

  # microvm leaves vfkit off its allowlist, which would split stage 1 per platform.
  boot.initrd.systemd.enable = true;

  # A lower-layer delete frees nothing but leaves a whiteout that persists on the
  # image and masks that path in any later boot whose closure contains it.
  boot.initrd.systemd.services.sweep-store-whiteouts = lib.mkIf config.boot.initrd.systemd.enable {
    description = "Remove overlayfs whiteouts from the writable store overlay";
    unitConfig.DefaultDependencies = false;
    after = [ "initrd-root-fs.target" ];
    before = [
      "${utils.escapeSystemdPath "/sysroot/nix/store"}.mount"
      "initrd-fs.target"
    ];
    requiredBy = [ "initrd-fs.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Else initrd-cleanup re-pulls it, after /nix/store is already mounted.
      RemainAfterExit = true;
    };
    script = sweepWhiteouts "/sysroot";
  };

  boot.initrd.postDeviceCommands =
    lib.mkIf (!config.boot.initrd.systemd.enable && lib.hasPrefix "/dev/" rootFs.device)
      ''
        mkdir -p /sweep
        if mount -t ${rootFs.fsType} ${rootFs.device} /sweep; then
          ${sweepWhiteouts "/sweep"}
          umount /sweep
        fi
      '';

  # Automatic because `ncl` needs a sudo password nobody can type. Reclaims only
  # the writable overlay; the read-only store is the host's to collect.
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "-d";
  };

  # The timer is Persistent, so it fires seconds after boot; unordered it beats
  # registration and collects the running closure as an unrooted path.
  systemd.services.nix-gc = {
    after = [ "register-store-closure.service" ];
    requires = [ "register-store-closure.service" ];
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

  # The forwarded host agent, so git authenticates with the host's YubiKey. Uses
  # the actual uid, not sandboxLib's, because Darwin renumbers the guest user.
  environment.variables.SSH_AUTH_SOCK = "/run/user/${toString config.users.users.w4cbe.uid}/gnupg/S.gpg-agent.ssh";

  # microvm.nix registers from postBootCommands, unordered against home-manager,
  # and without --store local, where nix picks the daemon and refuses.
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
      else
        echo "no regInfo= on the kernel command line" >&2
        exit 1
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
