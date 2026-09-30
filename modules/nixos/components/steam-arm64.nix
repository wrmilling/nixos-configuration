{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.steamArm64;
in
{
  options.modules.nixos.steamArm64 = {
    enable = lib.mkEnableOption "Valve's native aarch64 Steam client (steam-arm64-nix)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      inputs.steam-arm64-nix.packages.${pkgs.stdenv.hostPlatform.system}.steam-arm64
    ];

    hardware.steam-hardware.enable = true;
  };
}
