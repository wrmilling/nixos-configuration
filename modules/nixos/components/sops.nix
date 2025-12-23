{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
let
  cfg = config.modules.nixos.sops;
  isEd25519 = k: k.type == "ed25519";
  getKeyPath = k: k.path;
  keys = builtins.filter isEd25519 config.services.openssh.hostKeys;
in
{
  imports = [ inputs.sops-nix.nixosModules.sops ];

  options.modules.nixos.sops = {
    enable = lib.mkEnableOption "sops packages / settings";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      age.sshKeyPaths = map getKeyPath keys;
      defaultSopsFile = ../../../secrets/general.yaml;
    };
  };
}