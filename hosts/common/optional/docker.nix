{
  config,
  lib,
  pkgs,
  ...
}:
{
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    package = (
      pkgs.docker.override (args: {
        buildxSupport = true;
      })
    );
  };
}
