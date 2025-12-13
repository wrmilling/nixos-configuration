# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs ? (import ../nixpkgs.nix) { },
}:
{
  slides-git = pkgs.callPackage ./slides-git { };
  mcpelauncher-client-git = pkgs.callPackage ./mcpelauncher-client { };
  mcpelauncher-ui-qt-git = pkgs.callPackage ./mcpelauncher-ui-qt { };
}
