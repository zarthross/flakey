{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isDarwin {
        hot = pkgs.callPackage ./hot.pkg.nix { };
      };
    };
}
