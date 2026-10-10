# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs ? import <nixpkgs> { },
}:
rec {
  slides-git = pkgs.callPackage ./slides-git { };
  cc9s = pkgs.callPackage ./cc9s { };
  kubernetes-mcp-server = pkgs.callPackage ./kubernetes-mcp-server { };
  flux-operator-mcp = pkgs.callPackage ./flux-operator-mcp { };
  gomuks-desktop = pkgs.callPackage ./gomuks-desktop { };
  codegraph = pkgs.callPackage ./codegraph { };
  rea = pkgs.callPackage ./rea { };
  shiftleft-sl = pkgs.callPackage ./shiftleft-sl { };
  wizcli = pkgs.callPackage ./wizcli { };
  m5burner = pkgs.callPackage ./m5burner { };
  maki = pkgs.callPackage ./maki { };
  xr-video-player = pkgs.callPackage ./xr-video-player { };
  fusion360 = pkgs.callPackage ./fusion360 { };
  # Not callPackage: NixOS re-overrides the kernel, which needs the kernel's own .override, not callPackage's.
  linux-pinebook-pro = import ./linux-pinebook-pro { inherit (pkgs) lib linuxPackages_latest; };
  obsidianPlugins = import ./obsidianPlugins { inherit pkgs; };
}
