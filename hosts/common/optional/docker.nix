{
  config,
  lib,
  pkgs,
  ...
}: {
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
    package = (docker.override(args: { buildxSupport = true; }))
  };
}
