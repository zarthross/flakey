{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isDarwin {
        keepingYouAwake = pkgs.callPackage ./keeping-you-awake.pkg.nix { };
      };
    };
}
