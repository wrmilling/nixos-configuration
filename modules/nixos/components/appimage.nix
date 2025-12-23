{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.appimage;
in
{
  options.modules.nixos.appimage = {
    enable = lib.mkEnableOption "AppImage packages / settings";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.appimage-run ];

    boot.binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
  };
}
