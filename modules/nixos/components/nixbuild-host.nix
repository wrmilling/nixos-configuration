{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.nixos.nixbuildHost;
in
{
  options.modules.nixos.nixbuildHost = {
    enable = lib.mkEnableOption "nixbuild host packages / settings";
  };

  config = lib.mkIf cfg.enable {
    users.groups.nixbuild = { };

    users.users.nixbuild = {
      isSystemUser = true;
      group = "nixbuild";
      createHome = true;
      home = "/var/lib/nixbuild";
      shell = pkgs.bash;
      description = "Nix remote builder";
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJg6g95m4hjhES+SZx2fRY2EL6HNFVedpKHOuZuk4c/v nixbuild-client"
      ];
    };

    nix.settings.trusted-users = lib.mkAfter [ "nixbuild" ];
  };
}
