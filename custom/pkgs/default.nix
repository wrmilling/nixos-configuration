# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example' or (legacy) 'nix-build -A example'

{ pkgs ? (import ../nixpkgs.nix) { } }: {
  git-credential-manager = pkgs.callPackage ./git-credential-manager { };
  w4cbe-scripts = pkgs.callPackage ./w4cbe-scripts { };
}
