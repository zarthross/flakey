{ pkgs, stdenv }:

let
  sources = builtins.fromJSON (builtins.readFile ./sources.json);
  sys = if pkgs.system == "x86_64-darwin" then
    "x64"
  else if pkgs.system == "aarch64-darwin" then
    "arm64"
  else
    throw "unsupported system ${pkgs.system}";
in stdenv.mkDerivation rec {
  inherit (sources) version;
  pname = "Brave";

  buildInputs = [ pkgs.undmg ];
  sourceRoot = ".";
  phases = [ "unpackPhase" "installPhase" ];
  installPhase = ''
    mkdir -p $out/Applications
    cp -r Brave*.app "$out/Applications/"
  '';

  src = pkgs.fetchurl {
    name = "Brave-Browser-${sys}.dmg";
    url = sources.${sys}.url;
    hash = sources.${sys}.sha;
  };

  meta = {
    description =
      "We're reinventing the browser as a user-first platform for speed, privacy, better ads, and beyond";
    homepage = "https://brave.com/";
  };
}
