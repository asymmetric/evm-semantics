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
in
  with gitignore;

stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  additionalIgnores = ''
    .build/k
    tests
  '';
  src = gitignoreSourceAux additionalIgnores ./.;

  postPatch = ''
    substituteInPlace Makefile \
      --replace 'K_BIN=$(K_SUBMODULE)/k-distribution/target/release/k/bin' K_BIN=${k}/bin \
      --replace 'K_SUBMODULE:=$(BUILD_DIR)/k' K_SUBMODULE:=${k} \
  '';

  # ocamlDeps = with ocamlPackages; [ zarith ];
  buildInputs = [ bison flex gmp git k ncurses opam openjdk8 pandoc python3 z3 ]; # ++ ocamlDeps;

  buildPhase = ''
    make build-java
  '';

  installPhase = ''
    mkdir $out
  '';

  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
