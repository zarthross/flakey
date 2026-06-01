{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "rectangle";
in
stdenv.mkDerivation rec {
  pname = "Rectangle";
  version = "0.96";

  src = pkgs.fetchurl {
    url = "https://github.com/rxhanson/Rectangle/releases/download/v${version}/Rectangle${version}.dmg";
    hash = "sha256-FqNcIuRUH2J3UHFWRylSxF4r4pl20GLPJBdmkT0CcXk=";
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
