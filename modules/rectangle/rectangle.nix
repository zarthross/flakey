{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isDarwin {
        rectangle = pkgs.callPackage ./rectangle.pkg.nix { };
      };
    };
}
