{
  config,
  lib,
  ...
}:
let
  cfg = config.modules.nixos.chrony;
in
{
  options.modules.nixos.chrony = {
    enable = lib.mkEnableOption "chrony packages / settings";
  };

  config = lib.mkIf cfg.enable {
    services.chrony = {
      enable = true;
      enableNTS = true;
      servers = [
        "virginia.time.system76.com"
        "ohio.time.system76.com"
        "oregon.time.system76.com"
      ];
      # NTS-KE's TLS handshake validates cert dates against the system clock, so a
      # dead/missing RTC can deadlock sync entirely; skip that check for the first step.
      extraConfig = "nocerttimecheck 1";
    };
  };
}
