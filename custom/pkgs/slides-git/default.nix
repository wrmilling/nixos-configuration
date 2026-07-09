{
  lib,
  bash,
  buildGoModule,
  fetchFromGitHub,
  go,
}:

buildGoModule rec {
  pname = "slides";
  version = "0.9.0-unstable-2026-07-08";

  src = fetchFromGitHub {
    owner = "maaslalani";
    repo = "slides";
    rev = "92af1ef1f33a75bd51db9842a760bd228f3b1a61";
    sha256 = "sha256-eeueKw3ED86EenmrAvunvqwOaPa9Sd/iyQ1Z//NMwVY=";
  };

  nativeCheckInputs = [
    bash
    go
  ];

  vendorHash = "sha256-ULF6zzg1fY0xW4eUOC452XlnG3/Pxm+H9thyZO2OtDc=";

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
