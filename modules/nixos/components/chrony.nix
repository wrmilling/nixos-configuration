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

    makestepLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 3;
      description = ''
        services.chrony.makestep.limit -- the max number of times chronyd
        will step (rather than slew) the clock. Matches the upstream
        services.chrony default; raise it for hosts whose clock can be
        wrong by a lot at any point in their lifetime, not just at boot.
      '';
    };
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
      makestep.limit = cfg.makestepLimit;
    };
  };
}
