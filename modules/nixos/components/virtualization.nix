{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.virtualization;
in
{
  options.modules.nixos.virtualization = {
    enable = lib.mkEnableOption "virtualization packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.qemu
      pkgs.qemu-utils
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu.vhostUserPackages = with pkgs; [ virtiofsd ];
    };

    # TODO: Remove patch
    # https://github.com/NixOS/nixpkgs/issues/496836
    systemd.services."virt-secret-init-encryption".serviceConfig.ExecStart =
      lib.mkForce "/usr/bin/env bash -c 'umask 0077 && (dd if=/dev/random status=none bs=32 count=1 | systemd-creds encrypt --name=secrets-encryption-key - /var/lib/libvirt/secrets/secrets-encryption-key)'";

    programs.virt-manager.enable = true;
  };
}
