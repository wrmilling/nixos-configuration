{ config, pkgs, ... }:
{
  services.pcscd = {
    enable = true;
    plugins = [ pkgs.ccid ];
  };
}
