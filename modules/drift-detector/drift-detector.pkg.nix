{
  lib,
  stdenv,
  fetchurl,
  unzip,
}:

let
  sources = lib.importJSON ./sources.json;
  platform =
    sources.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "drift-detector";

  src = fetchurl {
    url = platform.url;
    hash = platform.hash;
  };

  nativeBuildInputs = [ unzip ];

  unpackPhase = ''
    unzip $src
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 drift_detector $out/bin/drift_detector

    runHook postInstall
  '';

  meta = with lib; {
    description = "Swift CLI that inspects Kubernetes deployments and compares them against latest GitHub release tags to identify version drift";
    homepage = "https://github.com/yellowstonesoftware/drift-detector";
    # No LICENSE file in upstream repo; omit license field rather than guess.
    platforms = [
      "x86_64-linux"
      "aarch64-darwin"
    ];
    mainProgram = "drift_detector";
  };
}
