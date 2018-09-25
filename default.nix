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

  src = gitignoreSource ./.;

  # ocamlDeps = with ocamlPackages; [ zarith ];
  buildInputs = [ flex k ncurses openjdk8 pandoc ];# ++ ocamlDeps;
  # preBuild = ''
  #     substituteInPlace Makefile --replace 'build-ocaml' \'\'
  # '';
}
