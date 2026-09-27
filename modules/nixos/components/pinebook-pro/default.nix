{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.pinebookPro;

  # CPU/GPU operating-point overclock/undervolt curve, applied to the current kernel's own dtb on every build.
  overclockedDtb =
    pkgs.runCommand "rk3399-pinebook-pro-overclocked.dtb"
      {
        nativeBuildInputs = [
          pkgs.dtc
          pkgs.python3
        ];
      }
      ''
        dtc -I dtb -O dts -o base.dts ${config.boot.kernelPackages.kernel}/dtbs/rockchip/rk3399-pinebook-pro.dtb
        python3 ${./patch-opp-tables.py} base.dts patched.dts
        dtc -I dts -O dtb -o $out patched.dts
      '';
in
{
  options.modules.nixos.pinebookPro = {
    enable = lib.mkEnableOption "Pinebook Pro kernel (USB-C DP alt mode) and overclocked device tree";
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-pinebook-pro;
    # cdn-dp (in rockchipdrm) and fusb302 defer until the Type-C PHY probes; keep eDP up in stage 1.
    boot.initrd.kernelModules = [ "phy_rockchip_typec" ];

    # The EDK2/TianoCore UEFI firmware loads the device tree from a fixed path, not a per-generation
    # devicetree= entry; refresh it from the current generation's kernel on every bootloader install.
    boot.loader.systemd-boot.extraInstallCommands = ''
      mkdir -p /boot/dtb/rockchip
      cp ${overclockedDtb} /boot/dtb/rockchip/rk3399-pinebook-pro.dtb
    '';
  };
}
