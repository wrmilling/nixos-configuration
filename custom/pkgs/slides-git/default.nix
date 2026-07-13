{
  lib,
  bash,
  buildGoModule,
  fetchFromGitHub,
  go,
}: let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version rev vendorHash;
in
buildGoModule rec {
  pname = "slides";
  inherit version vendorHash;

  src = fetchFromGitHub {
    owner = "maaslalani";
    repo = "slides";
    inherit rev;
    hash = versions.hash;
  };

  nativeCheckInputs = [
    bash
    go
  ];

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${version}"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Terminal based presentation tool";
    homepage = "https://github.com/maaslalani/slides";
    changelog = "https://github.com/maaslalani/slides/releases/tag/v${version}";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [
      maaslalani
      penguwin
    ];
    mainProgram = "slides";
  };
}
