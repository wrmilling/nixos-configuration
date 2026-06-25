# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs ? (import ../nixpkgs.nix) { },
}:
{
  slides-git = pkgs.callPackage ./slides-git { };
  mcpelauncher-client-git = pkgs.callPackage ./mcpelauncher-client { };
  mcpelauncher-ui-qt-git = pkgs.callPackage ./mcpelauncher-ui-qt { };
  kubernetes-mcp-server = pkgs.callPackage ./kubernetes-mcp-server { };
  flux-operator-mcp = pkgs.callPackage ./flux-operator-mcp { };
}
