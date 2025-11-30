{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.modules.dockerRootless;
in
{
  options.modules.dockerRootless = {
    enable = lib.mkEnableOption "docker rootless packages / settings";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker = {
      enable = false;
      rootless = {
        enable = true;
        setSocketVariable = true;
        package = (
          pkgs.docker.override (args: {
            buildxSupport = true;
          })
        );
      };
    };
  };
}