{
  config,
  lib,
  pkgs,
  ...
}: {
  services.chrony = {
    enable = true;
    enableNTS = true;
    servers = [
      "virginia.time.system76.com"
      "ohio.time.system76.com"
      "oregon.time.system76.com"
    ];
  };
}
