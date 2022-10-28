{pkgs, stdenv}:

let sources = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation rec {
   inherit (sources) version;
      pname = "Hot";

      buildInputs = [ pkgs.undmg pkgs.unzip ];
      sourceRoot = ".";
      phases = [ "unpackPhase" "installPhase" ];
      installPhase = ''
        mkdir -p $out/Applications
        cp -r Hot.app "$out/Applications/"
      '';

      src = pkgs.fetchurl {
        name = "Hot.app.zip";
        inherit (sources) url sha256;
      };

      meta = {
        description = "Hot is macOS menu bar application that displays the CPU speed limit due to thermal issues.";
        homepage = "https://xs-labs.com/en/apps/hot/overview/";
      };
}
