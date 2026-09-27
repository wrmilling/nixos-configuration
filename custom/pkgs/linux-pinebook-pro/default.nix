{ lib, linuxPackages_latest }:
let
  inherit (linuxPackages_latest) kernel;
  # Out-of-tree RK3399 Type-C DP series (Chaoyi Chen; v15 3,4,5,8/9 + v7 1-4,6,7/7) and the Pinebook Pro DTS change.
  typecDpPatches = map (patch: {
    name = baseNameOf patch;
    inherit patch;
  }) (lib.filesystem.listFilesRecursive ./patches);
in
lib.addMetaAttrs
  {
    description = "Latest nixpkgs Linux kernel with USB-C DisplayPort alt mode for the Pinebook Pro";
    platforms = [ "aarch64-linux" ];
  }
  (
    kernel.override {
      kernelPatches = kernel.kernelPatches ++ typecDpPatches;
    }
  )
