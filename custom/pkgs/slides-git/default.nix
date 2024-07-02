{
  lib,
  bash,
  buildGoModule,
  fetchFromGitHub,
  go,
}:

buildGoModule rec {
  pname = "slides";
  version = "0.10.0";

  src = fetchFromGitHub {
    owner = "maaslalani";
    repo = "slides";
    rev = "c6eea3330053045cede8d65ee1086fb5d4db6c43";
    sha256 = "sha256-fFKW1/+grANz7Znkkqk3X76rG+cxO57lfd24yx84HL8=";
  };

  nativeCheckInputs = [
    bash
    go
  ];

  vendorHash = "sha256-oV3UcbOC4y8xWnA5qZGEK/TRdQ4zCeZshgBAs2l+vSY=";

  ldflags = [
    "-s"
    "-w"
    "-X=main.Version=${version}"
  ];

  meta = with lib; {
    description = "Terminal based presentation tool";
    homepage = "https://github.com/maaslalani/slides";
    changelog = "https://github.com/maaslalani/slides/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [
      maaslalani
      penguwin
    ];
    mainProgram = "slides";
  };
}
