{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "omniwm";
in
stdenv.mkDerivation rec {
  pname = "OmniWM";
  version = "0.4.9.5";

  src = pkgs.fetchurl {
    url = "https://github.com/BarutSRB/OmniWM/releases/download/v${version}/OmniWM-v${version}.zip";
    hash = "sha256-h4ax/9LeRZwoT+TIptJIk078+66tynnc+ULmU57WZRA=";
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
