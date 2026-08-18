{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "bitwarden";
  sources = lib.importJSON ./sources.json;
in
stdenv.mkDerivation {
  pname = "Bitwarden";
  inherit (sources) version;

  src = pkgs.fetchurl {
    inherit (sources) url hash;
  };

  buildInputs = [ pkgs._7zz ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/Applications
    cp -r "Bitwarden ${sources.version}-universal/Bitwarden.app" "$out/Applications/"
  '';

  unpackPhase = ''
    7zz x -snld $src
  '';

  passthru.updateScript = pkgs.nix-update-script {
    extraArgs = [
      "--flake"
      packageName
      "--version-regex"
      "^desktop-v(.*)$"
    ];
  };

  meta = {
    description = "Open source password management solutions for individuals, teams, and business organizations";
    homepage = "https://bitwarden.com/";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = lib.platforms.darwin;
  };
}
