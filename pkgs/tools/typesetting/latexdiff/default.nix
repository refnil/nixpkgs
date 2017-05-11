{ stdenv, perl, texlive, fetchFromGitHub, AlgorithmDiff }:

stdenv.mkDerivation rec {
    name = "latexdiff";
    version = "1.2.0";
    src = fetchFromGitHub {
        owner = "ftilmann";
        repo  = "latexdiff";
        rev  = "1.2.0";
        sha256 = "1gafnfc0iv63ypwgx8bshiz8az9pjr1niik9dx51gm13h93ccam5";
    };

    buildPhase = ''
        mkdir -p dist
        make dist/latexdiff dist/latexrevise dist/latexdiff-vc
    '';

    installPhase = ''
        mkdir -p $out/bin
        cp -r dist/* $out/bin
    '';

    buildInputs = [ perl AlgorithmDiff ];
    nativeBuidlInputs = [ AlgorithmDiff ];
    propagatedNativeBuildInputs = [ AlgorithmDiff ];
    #propagatedBuildInputs = [ AlgorithmDiff ];
}

