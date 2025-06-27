{ pkgs, stdenv }:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "Bitwarden";

  buildInputs = [ pkgs._7zz ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/Applications
    cp -r Bitwarden*.app "$out/Applications/"
  '';

  unpackPhase = ''
    7zz x -snld $src
  '';

  src = pkgs.fetchurl {
    name = "Bitwarden-${version}.dmg";
    inherit (sources) url hash;
  };

  meta = {
    description = "Open source password management solutions for individuals, teams, and business organizations.";
    homepage = "https://bitwarden.com/";
  };
}
