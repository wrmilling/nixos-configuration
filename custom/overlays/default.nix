# This file defines overlays
{ inputs, ... }:
{
  # This one brings our custom packages from the 'pkgs' directory
  additions = final: _prev: import ../pkgs { pkgs = final; };

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays

  # Provides pkgs.claude-code from the sadjow/claude-code-nix flake.
  # Kept as a separate overlay so it can be selectively applied to home
  # configurations without touching NixOS hosts.
  claude-code = inputs.claude-code-nix.overlays.default;

  # Provides pkgs.fast-resume from the angristan/fast-resume flake's own
  # package output (no overlays output upstream, unlike claude-code-nix).
  fast-resume = final: _prev: {
    # Upstream package lacks the system libs cargoSetupHook now forces; drop once fixed.
    fast-resume =
      inputs.fast-resume.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs
        { dontCargoUseSystemLibs = true; };
  };

  claude-desktop = final: _prev: {
    claude-desktop =
      (import inputs.nixpkgs-claude-desktop {
        system = final.stdenv.hostPlatform.system;
        config.allowUnfree = true;
      }).claude-desktop;
  };

  modifications = final: prev: {
    # Broken by cargoSetupHook forcing system libs; drop once nixos-unstable has the fixes.
    codex = final.unstable-small.codex;
    viddy = prev.viddy.overrideAttrs (old: {
      buildInputs = (old.buildInputs or [ ]) ++ [ final.sqlite ];
    });
  };

  # When applied, the stable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.stable'
  stable-packages = final: _prev: {
    stable = import inputs.nixpkgs-stable {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };

  # When applied, the unstable-small nixpkgs set (declared in the flake inputs)
  # will be accessible through 'pkgs.unstable-small'
  unstable-small-packages = final: _prev: {
    unstable-small = import inputs.nixpkgs-unstable-small {
      system = final.stdenv.hostPlatform.system;
      config.allowUnfree = true;
    };
  };
}
