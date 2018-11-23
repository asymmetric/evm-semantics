{
  pkgs ? (import <nixpkgs> {}),
  k ? (import ((pkgs.fetchFromGitHub {
    owner   = "asymmetric";
    repo    = "k";
    rev     = "c6a996d6e96d4be2d6740cea340c24adbbfe4b44";
    sha256  = "1rv9c3dj90ybahgalj1j0yl0w160cgi67da5phbkd0dm2xs4hm27";
  }) + /nix) { }).build,
}:
with pkgs;

let
  opam-stub = writeScriptBin "opam" ''
    #!${bash}/bin/bash
    exit 0
  '';
in stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  src = ./.;

  patchPhase = ''
    sed -i 's#^K_BIN=.*$#K_BIN=${k}/bin#' Makefile
    sed -i 's#^K_SUBMODULE:=.*$#K_SUBMODULE:=${k}#' Makefile

    # change the lookup paths passed to kompile
    sed -i "s#-I .build/java#-I $out/.build/java --cache-file $out/cache.bin#" Makefile
    sed -i "s#--directory .build/java#--directory $out/.build/java#" Makefile

    sed -i "s#BUILD_DIR:=.*/\(.*\)\$#BUILD_DIR:=$out/\1#" Makefile

    sed -i 's#^build_dir:=\(.*\)#build_dir:=../../\1#' tests/proofs/Makefile
    sed -i 's#^kevm_repo_dir:=.*$#kevm_repo_dir:=../..#' tests/proofs/Makefile
  '';

  buildInputs = [ bison flex gmp git k makeWrapper ncurses opam-stub openjdk8 pandoc python3 ];

  buildPhase = ''
    mkdir -p $out/.build
    make build-java split-tests
  '';

  installPhase = ''
    mkdir -p $out/{bin,tests}
    cp -t $out/bin kast-json.py kevm
    patchShebangs $out/bin

    cp -R .build $out

    cp -R tests/proofs $out/tests
    mkdir $out/.build/logs
  '';

  fixupPhase = ''
    sed -i "s#\$build_dir#$out/.build#" $out/bin/kevm

    wrapProgram $out/bin/kevm \
      --prefix PATH : ${lib.makeBinPath [ gcc k opam-stub openjdk8 z3 ]} \
      --set K_BIN ${k}
  '';
}
