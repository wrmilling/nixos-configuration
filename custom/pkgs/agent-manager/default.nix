{
  lib,
  buildGoModule,
  fetchFromGitHub,
  git,
}:
let
  versions = lib.importJSON ./versions.json;
  inherit (versions) version vendorHash;
in
buildGoModule rec {
  pname = "agent-manager";
  inherit version vendorHash;

  src = fetchFromGitHub {
    owner = "YoanWai";
    repo = "agent-manager";
    rev = "v${version}";
    hash = versions.hash;
  };

  # go.mod pins a go directive patch version ahead of nixpkgs' go; the
  # requirement is a toolchain bump, not a language feature this needs.
  postPatch = ''
    substituteInPlace go.mod --replace-fail "go 1.26.5" "go 1.26.4"
  '';

  nativeCheckInputs = [ git ];

  # TestTreesSelf reads /proc for the running test process, which the nix
  # build sandbox restricts.
  checkFlags = [ "-skip=TestTreesSelf" ];

  ldflags = [
    "-s"
    "-w"
  ];

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Terminal UI for managing multiple AI coding-agent sessions in tmux";
    homepage = "https://github.com/YoanWai/agent-manager";
    changelog = "https://github.com/YoanWai/agent-manager/releases/tag/v${version}";
    license = lib.licenses.mit;
    mainProgram = "agent-manager";
  };
}
