{pkgs, stdenv}:

let sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
   inherit (sources) version;
      pname = "Rectangle";

      buildInputs = [ pkgs.undmg ];
      sourceRoot = ".";
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p $out/Applications
        cp -r Rectangle*.app "$out/Applications/"
      '';

      src = pkgs.fetchurl {
        name = "Rectangle-v${version}.dmg";
        inherit (sources) url sha256;
      };

      meta = {
        description = "Move and resize windows on macOS with keyboard shortcuts and snap areas";
        homepage = "https://rectangleapp.com/";
      };
}
