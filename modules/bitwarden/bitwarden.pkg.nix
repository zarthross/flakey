{
  pkgs,
  stdenv,
  lib,
}:

let
  packageName = "bitwarden";
in
stdenv.mkDerivation rec {
  pname = "Bitwarden";
  version = "2026.5.0";

  src = pkgs.fetchurl {
    url = "https://github.com/bitwarden/clients/releases/download/desktop-v${version}/Bitwarden-${version}-universal.dmg";
    hash = "sha256-THP1ro+VmWQ57JbIy1wS7vAdZnz4v746VKYrJrduZOM=";
  };

  buildInputs = [ pkgs._7zz ];
  sourceRoot = ".";
  phases = [
    "unpackPhase"
    "installPhase"
  ];

  installPhase = ''
    mkdir -p $out/Applications
    cp -r "Bitwarden ${version}-universal/Bitwarden.app" "$out/Applications/"
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
