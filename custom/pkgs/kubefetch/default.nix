{
  stdenv,
  lib,
  fetchFromGitHub,
  buildGoModule,
}:
buildGoModule rec {
  pname = "kubefetch";
  version = "0.7.2";

  src = fetchFromGitHub {
    owner = "jkulzer";
    repo = "kubefetch";
    rev = "${version}";
    hash = "sha256-ksnqlfm++Np5I7ZUXvVPgm3T2hHM6x9sAWdmK0Whn5k=";
  };

  vendorHash = "sha256-qsncOsCxepySJI+rJnzbIGxSWlxMzqShtzcEoJD2UPw=";

  meta = with lib; {
    description = "Neofetch for Kubernetes Clusters";
    longDescription = ''
      A neofetch-like tool to show info about you Kubernetes Cluster.
    '';
    homepage = "https://github.com/jkulzer/kubefetch";
    license = licenses.gpl3;
    maintainers = with maintainers; [wrmilling];
  };
}
