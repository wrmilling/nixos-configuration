{
  pkgs,
  lib,
  config,
  ...
}:
{
  home.packages = [ 
    pkgs.chirp 
  ];
}
