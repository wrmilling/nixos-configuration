{
  lib,
  buildGoModule,
  fetchFromGitHub,
}: let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version vendorHash;
in
buildGoModule rec {
  pname = "cc9s";
  inherit version vendorHash;

  src = fetchFromGitHub {
    owner = "kincoy";
    repo = "cc9s";
    rev = "v${version}";
    hash = versions.hash;
  };

  ldflags = [
    "-s"
    "-w"
  ];

  meta = {
    description = "A k9s-inspired CLI and TUI for managing Claude Code sessions";
    homepage = "https://github.com/kincoy/cc9s";
    changelog = "https://github.com/kincoy/cc9s/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "cc9s";
  };
}
