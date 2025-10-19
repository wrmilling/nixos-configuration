{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.docker = {
    enabled = false;
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
