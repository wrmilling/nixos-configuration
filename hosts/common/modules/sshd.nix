{ config, lib, pkgs, ... }:

{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  # Enable Fail2Ban
  services.fail2ban.enable = lib.mkDefault true;
}
