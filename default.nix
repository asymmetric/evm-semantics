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
stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  src = ./.;

  patchPhase = ''
    for file in .build/k/k-distribution/bin/*; do
      [ -f $file ] && substituteInPlace $file --replace "/usr/bin/env " ${bash}/bin/
    done
    for file in .build/k/k-distribution/lib/*; do
      [ -f $file ] && substituteInPlace $file --replace "/usr/bin/env " ${bash}/bin/
    done
  '';

  # ocamlDeps = with ocamlPackages; [ zarith ];
  buildInputs = [ flex k ncurses openjdk8 pandoc ];# ++ ocamlDeps;
  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
