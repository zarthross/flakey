{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        hot = pkgs.callPackage ./hot.pkg.nix { };
      };
    };
}
