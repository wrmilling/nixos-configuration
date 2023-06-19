{ pkgs, stdenv }:

stdenv.mkDerivation rec {
	pname = "w4cbe-scripts";
	version = "0.0.1";

	src = ".";

	installPhase = ''
		mkdir -p $out/bin
		cp bsodlock $out/bin
	'';

	meta = with pkgs.lib; {
    description = "Personal helper shell scripts";
    homepage = "https://winston.milli.ng";
    license = licenses.bsd3;
    maintainers = with maintainers; [ wrmilling ];
  };
}
