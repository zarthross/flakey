{
  lib,
  stdenv,
  fetchzip,
}:

let
  # Map Nix system to ECA release platform
  platformInfo = {
    "x86_64-linux" = {
      url = "eca-native-static-linux-amd64.zip";
      sha256 = "";
    };
    "aarch64-linux" = {
      url = "eca-native-linux-aarch64.zip";
      sha256 = "";
    };
    "x86_64-darwin" = {
      url = "eca-native-macos-amd64.zip";
      sha256 = "";
    };
    "aarch64-darwin" = {
      url = "eca-native-macos-aarch64.zip";
      sha256 = "sha256-F5HJp4pKFUmgamv4uynpUgx90FaMnid8fuaP30U/uio=";
    };
  };

  platform =
    platformInfo.${stdenv.hostPlatform.system}
      or (throw "Unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation rec {
  pname = "eca-bin";
  version = "0.136.0";

  src = fetchzip {
    url = "https://github.com/editor-code-assistant/eca/releases/download/${version}/${platform.url}";
    sha256 = platform.sha256;
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    install -Dm755 eca $out/bin/eca

    runHook postInstall
  '';

  meta = with lib; {
    description = "Editor Code Assistant (ECA) - AI pair programming capabilities agnostic of editor";
    homepage = "https://eca.dev";
    license = licenses.mit;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "eca";
  };
}
