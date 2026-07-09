{
  lib,
  buildGoModule,
  fetchFromGitHub,
}:

buildGoModule rec {
  pname = "cc9s";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "kincoy";
    repo = "cc9s";
    rev = "v${version}";
    sha256 = "sha256-FFDwLpSyzSR8TEi6z9vTRIExBtqwKTZQ1Il002HsjCM=";
  };

  vendorHash = "sha256-BUI/+bSDi7Qgo6UC8Esl7MVzQm10X7iVKndLNYqDQrE=";

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
