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
  pname = "KeepingYouAwake";

  src = pkgs.fetchurl {
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
    cp -r KeepingYouAwake.app "$out/Applications/"
  '';

  meta = {
    description = "Prevents your Mac from going to sleep";
    homepage = "https://keepingyouawake.app/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
