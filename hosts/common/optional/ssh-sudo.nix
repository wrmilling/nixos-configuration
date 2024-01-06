{
  config,
  lib,
  pkgs,
  ...
}: {
  security.pam.enableSSHAgentAuth = true;
  security.pam.services.sudo.sshAgentAuth = true;
}
