{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "rectangle";
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation rec {
  pname = "Rectangle";
  inherit (sources) version;

  src = pkgs.fetchurl {
    inherit (sources) url sha256;
  };

  buildInputs = [ pkgs.undmg ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];
  installPhase = ''
    mkdir -p $out/Applications
    cp -r Rectangle*.app "$out/Applications/"
  '';

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [
      "--flake"
      packageName
    ];
  };

  meta = {
    description = "Move and resize windows on macOS with keyboard shortcuts and snap areas";
    homepage = "https://rectangleapp.com/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
