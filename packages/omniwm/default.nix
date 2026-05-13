{ pkgs, stdenv }:
let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "OmniWM";
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
  src = pkgs.fetchurl {
    name = "OmniWM-${version}.zip";
    inherit (sources) url sha256;
  };
  meta = {
    description = "macOS tiling window manager inspired by Niri and Hyprland, developer signed and notarized.";
    homepage = "https://barutsrb.github.io/OmniWM/";
  };
}
