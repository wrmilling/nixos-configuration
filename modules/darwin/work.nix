{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.darwin.work;
in
{
  # Re-use the NixOS Module where possible
  options.modules.darwin.work = {
    enable = lib.mkEnableOption "darwin work modules";
  };

  config = lib.mkIf cfg.enable {
    modules = {
      darwin.base.enable = true;
    };
  };

  programs.fish.shellInit = ''
      set -gx SSL_CERT_FILE /usr/local/munki/thd_certs.pem
      set -gx NIX_SSL_CERT_FILE /usr/local/munki/thd_certs.pem
      set -gx NODE_EXTRA_CA_CERTS /usr/local/munki/thd_certs.pem
      set -gx REQUESTS_CA_BUNDLE /usr/local/munki/thd_certs.pem
    '';
}
