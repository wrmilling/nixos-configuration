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
      pkgs.OVMF
    ];

    virtualisation.libvirtd = {
      enable = true;
      qemu = {
        vhostUserPackages = with pkgs; [ virtiofsd ];
        swtpm.enable = true;
      };  
    };

    programs.virt-manager.enable = true;
  };
}
