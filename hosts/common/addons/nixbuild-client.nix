{ config, lib, pkgs, ... }:

# This file needs to be re-worked

# let secrets = import ../../../secrets.nix; in

{
  programs.ssh.extraConfig = ''
    Host nixbuild.${secrets.DOMAIN}
      HostName hermes.${secrets.DOMAIN}
      User nixbuild
      PubkeyAcceptedKeyTypes ssh-ed25519
      IdentityFile /etc/nixbuild/nixbuild-client
  '';

  programs.ssh.knownHosts = {
    nixbuild = {
      hostNames = [ "hermes.${secrets.DOMAIN}" ];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBKDavFNkNXvfryxtWJHcaJkAnYxGQBpWUNEG4yNKLkt";
    };
  };

  nix = {
    distributedBuilds = true;
    buildMachines = [
      { hostName = "hermes.${secrets.DOMAIN}";
        system = "aarch64-linux";
        maxJobs = 4;
        supportedFeatures = [  ];
      }
    ];
  };
}
