# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'
{
  pkgs ? import <nixpkgs> { },
}:
{
  slides-git = pkgs.callPackage ./slides-git { };
  cc9s = pkgs.callPackage ./cc9s { };
  mcpelauncher-client-git = pkgs.callPackage ./mcpelauncher-client { };
  mcpelauncher-ui-qt-git = pkgs.callPackage ./mcpelauncher-ui-qt { };
  kubernetes-mcp-server = pkgs.callPackage ./kubernetes-mcp-server { };
  flux-operator-mcp = pkgs.callPackage ./flux-operator-mcp { };
  gomuks-desktop = pkgs.callPackage ./gomuks-desktop { };
  codegraph = pkgs.callPackage ./codegraph { };
  shiftleft-sl = pkgs.callPackage ./shiftleft-sl { };
  m5burner = pkgs.callPackage ./m5burner { };
  appflowy = pkgs.callPackage ./appflowy { };
}
