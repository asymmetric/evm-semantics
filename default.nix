{
  pkgs ? (import <nixpkgs> {}),
  k ? (import ((pkgs.fetchFromGitHub {
    owner   = "asymmetric";
    repo    = "k";
    rev     = "2359a872136ecf938ccc6c288fd99e3308667601";
    sha256  = "0x44is741brpdn051q7vcvbdnz7cd7688z5hp48cc0nchpvfcvfz";
  }) + /nix) { }).build,
}:
with pkgs;

let
  gitignore = import (fetchFromGitHub {
    owner   = "siers";
    repo    = "nix-gitignore";
    rev     = "7a2a637fa4a753a9ca11f60eab52b35241ee3c2f";
    sha256  = "0hrins85jz521nikmrmsgrz8nqawj52j6abxfcwjy38rqixcw8y1";
  }) { inherit lib; };

  opam-stub = writeScriptBin "opam" ''
    #!${bash}/bin/bash
    exit 0
  '';
in stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  src = gitignore.gitignoreSource ./.;

  patchPhase = ''
    sed -i 's#^K_BIN=.*$#K_BIN=${k}/bin#' Makefile
    sed -i 's#^K_SUBMODULE:=.*$#K_SUBMODULE:=${k}#' Makefile
    sed -i 's#-I .build/\(java|haskell\)$#-I $out/.build/\1#' Makefile

    sed -i "s#BUILD_DIR:=.*/\(.*\)$#BUILD_DIR:=$out/\1#" Makefile

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
    cp kevm $out/bin/

    cp -R .build $out/
    cp -R tests/proofs $out/tests
    mkdir $out/.build/logs
  '';

  fixupPhase = ''
    set -x
    sed -i 's#^build_dir=\(.*\)/#build_dir=\1/../#' $out/bin/kevm
    sed -i "s#kprove --directory \"\$build_dir/java/\"#kprove --directory \"$PWD\"#" $out/bin/kevm

    wrapProgram $out/bin/kevm \
      --prefix PATH : ${lib.makeBinPath [ k opam-stub openjdk8 z3 ]} \
      --set K_BIN ${k}
  '';
}
