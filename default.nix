{
  pkgs ? (import <nixpkgs> {}),
}:

with pkgs;
stdenv.mkDerivation rec {
  name    = "kevm";
  version = "2018-09-25";

  src = ./.;

  # ocamlDeps = with ocamlPackages; [ zarith ];
  buildInputs = [ flex ncurses openjdk8 pandoc ];# ++ ocamlDeps;
  patchPhase = ''
    for file in .build/k/k-distribution/bin/*; do
      [ -f $file ] && substituteInPlace $file --replace "/usr/bin/env " ${bash}/bin/
    done
    for file in .build/k/k-distribution/lib/*; do
      [ -f $file ] && substituteInPlace $file --replace "/usr/bin/env " ${bash}/bin/
    done
  '';
  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
