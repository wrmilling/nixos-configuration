# Autowiring helper functions for auto-discovering configurations and modules
{ lib }:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    nameValuePair
    hasSuffix
    removeSuffix
    attrNames
    pathExists
    concatMapAttrs
    elem
    ;
  inherit (builtins) readDir;

  # Helper: Filter and map attributes in one pass
  mapFilterAttrs =
    pred: f: attrs:
    filterAttrs pred (mapAttrs' f attrs);

  # Helper: Check if path is a valid nix file or directory with default.nix
  isNixEntry =
    name: type:
    (type == "regular" && hasSuffix ".nix" name && name != "default.nix")
    || (type == "directory" && pathExists (name + "/default.nix"));

  # Helper: Get configuration name from filename or directory
  getConfigName = name: type: if type == "directory" then name else removeSuffix ".nix" name;

  # Safely read directory, returning empty set if path doesn't exist
  safeReadDir = dir: if pathExists dir then readDir dir else { };
in
{
  # Discover and import modules from a directory
  # Each .nix file or directory becomes a module export
  discoverModules =
    { dir }:
    mapFilterAttrs (_: v: v != null) (
      name: type:
      let
        isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
        isValidDir = type == "directory" && pathExists (dir + "/${name}/default.nix");
      in
      if isValidNixFile then
        nameValuePair (removeSuffix ".nix" name) (import (dir + "/${name}"))
      else if isValidDir then
        nameValuePair name (import (dir + "/${name}"))
      else
        nameValuePair "" null
    ) (safeReadDir dir);

  # Discover overlays from a directory
  discoverOverlays =
    { dir, inputs }:
    mapFilterAttrs (_: v: v != null) (
      name: type:
      let
        isValidNixFile = type == "regular" && hasSuffix ".nix" name && name != "default.nix";
      in
      if isValidNixFile then
        nameValuePair (removeSuffix ".nix" name) (import (dir + "/${name}") { inherit inputs; })
      else
        nameValuePair "" null
    ) (safeReadDir dir);

  # Discover packages from a directory
  # Each .nix file should be callPackage-compatible
  discoverPackages =
    { dir, pkgs }:
    mapFilterAttrs (_: v: v != null) (
      name: type:
      if type == "regular" && hasSuffix ".nix" name && name != "default.nix" then
        nameValuePair (removeSuffix ".nix" name) (pkgs.callPackage (dir + "/${name}") { })
      else
        nameValuePair "" null
    ) (safeReadDir dir);
}
