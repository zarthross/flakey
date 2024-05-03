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
      packages =
        if pkgs.stdenv.isDarwin then
          {
            brave = pkgs.callPackage ./brave { };
            bitwarden = pkgs.callPackage ./bitwarden { };
            hot = pkgs.callPackage ./hot { };
            keepingYouAwake = pkgs.callPackage ./KeepingYouAwake { };
            rectangle = pkgs.callPackage ./rectangle { };
          }
        else
          { };
    };
}
