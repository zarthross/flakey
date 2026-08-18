{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        rectangle = pkgs.callPackage ./rectangle.pkg.nix { };
      };
    };
}
