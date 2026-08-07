{
  pkgs,
  stdenv,
  lib,
}:

let
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "Hot";

  src = pkgs.fetchurl {
    name = "Hot.app.zip";
    inherit (sources) url sha256;
  };

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
    cp -r Hot.app "$out/Applications/"
  '';

  meta = {
    description = "macOS menu bar application that displays the CPU speed limit due to thermal issues";
    homepage = "https://xs-labs.com/en/apps/hot/overview/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
