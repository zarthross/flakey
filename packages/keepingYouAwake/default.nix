{ pkgs, stdenv, lib }:

let
  packageName = "keepingYouAwake";
in
stdenv.mkDerivation rec {
  pname = "KeepingYouAwake";
  version = "1.6.8";

  src = pkgs.fetchurl {
    url = "https://github.com/newmarcel/KeepingYouAwake/releases/download/${version}/KeepingYouAwake-${version}.zip";
    hash = "sha256-gAGhSbRJDACP2sGYmLzpkC1RbEqmQSp+sPmjdEOxXGs=";
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

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [
      "--flake"
      packageName
    ];
  };

  meta = {
    description = "Prevents your Mac from going to sleep";
    homepage = "https://keepingyouawake.app/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
