{
  config,
  lib,
  pkgs,
  ...
}:
{
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
}
