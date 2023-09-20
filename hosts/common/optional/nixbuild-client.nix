{ config, lib, pkgs, ... }:

{
  programs.ssh.extraConfig = ''
    Host nixbuild.${config.networking.domain}
      HostName hermes.${config.networking.domain}
      User nixbuild
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentityFile /etc/nixbuild/nixbuild-client
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "hermes.${config.networking.domain}" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIrbzUeLjwiQIRcvlojBpdza702AIl1ne5upGVzKBE1n";
    };
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      { hostName = "hermes.${config.networking.domain}";
        system = "aarch64-linux";
        maxJobs = 4;
        supportedFeatures = [  ];
      }
    ];
  };
}
