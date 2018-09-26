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

  additionalIgnores = ''
    .build/k
    tests
  '';
  src = gitignore.gitignoreSourceAux additionalIgnores ./.;

  patchPhase = ''
    sed -i 's|^K_BIN=.*$|K_BIN=${k}/bin|' Makefile
    sed -i 's|^K_SUBMODULE:=.*$|K_SUBMODULE:=${k}|' Makefile
  '';

  buildInputs = [ bison flex gmp git makeWrapper ncurses opam-stub openjdk8 pandoc python3 ];

  buildPhase = ''
    make build-java
  '';

  installPhase = ''
    mkdir -p $out/{bin,logs}
    cp kevm $out/bin
    cp -R .build $out
  '';

  fixupPhase = ''
    wrapProgram $out/bin/kevm --prefix PATH : ${lib.makeBinPath [ k opam-stub z3 ]}
  '';

  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
