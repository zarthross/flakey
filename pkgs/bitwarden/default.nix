{pkgs, stdenv}:

let sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
   inherit (sources) version;
      pname = "Bitwarden";

      buildInputs = [ pkgs.undmg ];
      sourceRoot = ".";
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p $out/Applications
        cp -r Bitwarden*.app "$out/Applications/"
      '';

      src = pkgs.fetchurl {
        name = "Bitwarden-${version}.dmg";
        inherit (sources) url hash;
      };

      meta = {
        description = "Move and resize windows on macOS with keyboard shortcuts and snap areas";
        homepage = "https://rectangleapp.com/";
      };
}
