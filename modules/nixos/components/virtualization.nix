{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.virtualization;
in
{
  options.modules.virtualization = {
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

    programs.virt-manager.enable = true;
  };
}