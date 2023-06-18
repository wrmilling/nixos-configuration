{ config, lib, pkgs, ... }:

{
  # boot.kernelModules = lib.mkAfter [ "zram" ];

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 150;
  };
}
