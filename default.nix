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
  gitignore = callPackage (fetchFromGitHub {
    owner   = "siers";
    repo    = "nix-gitignore";
    rev     = "18de2d6f6c164a3524bd7d32785e16b73e961bb9";
    sha256  = "0k0gicqvg6mzac1a96cgbwjnq5r8514pbgvfcczj4kb67m3rdmwc";
  }) { };

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

    cp -R .build $out

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
