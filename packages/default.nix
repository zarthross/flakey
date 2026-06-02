{
  self,
  lib,
  inputs,
  specialArgs,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.easyOverlay ];
  perSystem =
    {
      config,
      self',
      inputs',
      pkgs,
      system,
      ...
    }:
    {
      overlayAttrs = config.packages;
      packages = {
        eca-bin = pkgs.callPackage ./eca-bin { };
      }
      // (
        if pkgs.stdenv.isDarwin then
          {
            bitwarden = pkgs.callPackage ./bitwarden { };
            hot = pkgs.callPackage ./hot { };
            keepingYouAwake = pkgs.callPackage ./keepingYouAwake { };
            omniwm = pkgs.callPackage ./omniwm { };
            rectangle = pkgs.callPackage ./rectangle { };
          }
        else
          { }
      );

      # Add all packages as checks so `nix flake check` builds them
      checks = lib.mapAttrs' (name: pkg: lib.nameValuePair "package-${name}" pkg) config.packages;
    };
}
