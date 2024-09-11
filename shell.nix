# Shell for bootstrapping flake-enabled nix and home-manager
# You can enter it through 'nix develop' or (legacy) 'nix-shell'
{
  pkgs ? (import ./nixpkgs.nix) { },
}:
{
  default = pkgs.mkShell {
    # Enable experimental features without having to specify the argument
    NIX_CONFIG = "experimental-features = nix-command flakes";
    # nativeBuildInputs = [ pkgs.nix pkgs.home-manager pkgs.git ];
    nativeBuildInputs = [
      pkgs.nix
      pkgs.vim
      pkgs.git
      pkgs.git-crypt
      pkgs.magic-wormhole-rs
    ];
  };
}
