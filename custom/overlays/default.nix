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

  modifications = final: prev: {
    # example = prev.example.overrideAttrs (oldAttrs: rec {
    # ...
    # });
    opencode =
      inputs.opencode-git.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs
        (oldAttrs: {
          postPatch = (oldAttrs.postPatch or "") + ''
            # https://github.com/NixOS/nixpkgs/pull/508770
            substituteInPlace package.json --replace-fail 'bun@1.3.14' 'bun@1.3.11'

            substituteInPlace packages/opencode/script/build.ts \
              --replace-warn 'await createEmbeddedWebUIBundle()' 'console.log("Skipping Web UI build")'
          '';
        });

    # Pin to 2.63.5; latest release breaks symlink handling
    filebrowser =
      (import inputs.nixpkgs-filebrowser { system = final.system; config.allowUnfree = true; }).filebrowser;

    openldap = prev.openldap.overrideAttrs {
      doCheck = !prev.stdenv.hostPlatform.isi686;
    };

    # nixpkgs PR #510918: linuxPackages.facetimehd 0.6.13 -> 0.7.0.1
    linuxPackagesFor =
      kernel:
      (prev.linuxPackagesFor kernel).extend (
        lpFinal: lpPrev: {
          facetimehd = lpPrev.facetimehd.overrideAttrs (oldAttrs: {
            version = "0.7.0.1";
            src = oldAttrs.src.override {
              rev = "0.7.0.1";
              sha256 = "sha256-VDEG0EsmkNLxXoQDGQV1HMX8Yg8YjoGLJ8NSerGms0I=";
            };
          });
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
