{ pkgs, stdenv }:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "KeepingYouAwake";

  buildInputs = [
    pkgs.undmg
    pkgs.unzip
  ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  installPhase = ''
    mkdir -p $out/Applications
    cp -r KeepingYouAwake.app "$out/Applications/"
  '';

  src = pkgs.fetchurl {
    name = "KeepingYouAwake-${version}.zip";
    inherit (sources) url sha256;
  };

  meta = {
    description = " Prevents your Mac from going to sleep. ";
    homepage = "https://keepingyouawake.app/";
  };
}
