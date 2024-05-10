# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # When applied, the lilyinstarlight nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.lilyinstarlight'
  # lilyinstarlight-packages = final: _prev: {
  #   lilyinstarlight = import inputs.nixpkgs-lilyinstarlight {
  #     system = final.system;
  #     config.allowUnfree = true;
  #   };
  # };
}
