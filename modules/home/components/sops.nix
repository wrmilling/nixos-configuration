{
  config,
  lib,
  inputs,
  ...
}:
let
  cfg = config.modules.home.sops;
in
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  options.modules.home.sops = {
    enable = lib.mkEnableOption "sops-nix secret management for home-manager";
  };

  config = lib.mkIf cfg.enable {
    sops = {
      # Per-user age key. Generate with `age-keygen` (see secrets/README.md) and
      # place the private key here. The public key goes in .sops.yaml creation rules.
      age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
      # No defaultSopsFile by design: each secret sets its own `sopsFile`.
    };
  };
}
