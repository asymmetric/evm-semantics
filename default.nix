{
  pkgs ? (import <nixpkgs> {}),
  k ? (import ((pkgs.fetchFromGitHub {
    owner   = "asymmetric";
    repo    = "k";
    rev     = "7a53cb6758f61b6dc276a840c7fa7a622b57d13a";
    sha256  = "0ac84p3wb3hwvghm5g0mlqfbygx67ra9mlzld0krqbd2hqdavnp4";
  }) + /nix) { }).build,
}:
with pkgs;

let
  gitignore = callPackage (fetchFromGitHub {
    owner   = "siers";
    repo    = "nix-gitignore";
    rev     = "221d4aea15b4b7cc957977867fd1075b279837b3";
    sha256  = "0xgxzjazb6qzn9y27b2srsp2h9pndjh3zjpbxpmhz0awdi7h8y9m";
  }) { };

  opam-stub = writeScriptBin "opam" ''
    #!${bash}/bin/bash
    exit 0
  '';
in stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  src = gitignore.gitignoreSource [] ./.;

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
