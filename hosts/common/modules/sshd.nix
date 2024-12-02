{
  config,
  lib,
  pkgs,
  ...
}:

let
  secrets = import ../../../secrets/secrets.nix;
in
{
  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = lib.mkDefault true;
    banner = secrets.sshd.banner;
    settings = {
      PermitRootLogin = lib.mkDefault "no";
      PasswordAuthentication = lib.mkDefault false;
    };
  };

  # Enable Fail2Ban
  services.fail2ban.enable = lib.mkDefault true;
}
