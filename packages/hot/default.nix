{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "hot";
in
stdenv.mkDerivation rec {
  pname = "Hot";
  version = "1.9.4";

  src = pkgs.fetchurl {
    url = "https://github.com/macmade/Hot/releases/download/${version}/Hot.zip";
    hash = "sha256-5PbM92Bmc+5hGHC/sdTMi+hqUIBY24+btc9B6ZftYco=";
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

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [
      "--flake"
      packageName
    ];
  };

  meta = {
    description = "macOS menu bar application that displays the CPU speed limit due to thermal issues";
    homepage = "https://xs-labs.com/en/apps/hot/overview/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
