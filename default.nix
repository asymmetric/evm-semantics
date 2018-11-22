{
  pkgs ? (import <nixpkgs> {}),
  k ? (import ((pkgs.fetchFromGitHub {
    owner   = "asymmetric";
    repo    = "k";
    rev     = "0f8c1bb9f6b661362358a8137bb0187e334f7ee3";
    sha256  = "0bxhia9n226v4iz7p44x1zn06kwvvhnw2wjg099apg0h3r8rzxfg";
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

    # change the lookup paths passed to kompile
    sed -i "s#-I .build/java#-I $out/.build/java#" Makefile
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
