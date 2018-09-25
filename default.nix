{
  pkgs ? (import <nixpkgs> {}),
  k ? (import ((pkgs.fetchFromGitHub {
    owner   = "asymmetric";
    repo    = "k";
    rev     = "dc9a62f7d12559e7e2b0a020aea9e3260639b4b5";
    sha256  = "0ms59s3bl0bb085wqckl8m6vjpis9imjjgmdf6j83yrfhim0p96p";
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

  src = gitignoreSource ./.;

  patchPhase = ''
    for file in .build/k/k-distribution/{bin,lib}/*; do
      [ -f $file ] && substituteInPlace $file \
        --replace "/usr/bin/env sh" ${bash}/bin/sh \
        --replace "/usr/bin/env bash" ${bash}/bin/bash
    done
  '';

  # ocamlDeps = with ocamlPackages; [ zarith ];
  buildInputs = [ flex k ncurses openjdk8 pandoc ];# ++ ocamlDeps;
  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
