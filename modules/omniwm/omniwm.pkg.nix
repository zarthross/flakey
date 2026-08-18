{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "omniwm";
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation rec {
  pname = "OmniWM";
  inherit (sources) version;

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
    cp -r OmniWM.app "$out/Applications/"
  '';

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [
      "--flake"
      packageName
    ];
  };

  meta = {
    description = "macOS tiling window manager inspired by Niri and Hyprland, developer signed and notarized";
    homepage = "https://barutsrb.github.io/OmniWM/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
