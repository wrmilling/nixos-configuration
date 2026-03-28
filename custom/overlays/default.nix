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
    opencode = inputs.opencode-git.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs (
      oldAttrs: {
      postPatch = (oldAttrs.postPatch or "") + ''
        substituteInPlace packages/opencode/script/build.ts \
          --replace-warn 'await createEmbeddedWebUIBundle()' 'console.log("Skipping Web UI build")'
      '';
      }
    );
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.system;
      config.allowUnfree = true;
    };
  };

  # When applied, the unstable-small nixpkgs set (declared in the flake inputs)
  # will be accessible through 'pkgs.unstable-small'
  unstable-small-packages = final: _prev: {
    unstable-small = import inputs.nixpkgs-unstable-small {
      system = final.system;
      config.allowUnfree = true;
    };
  };
}
