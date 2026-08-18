{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        keepingYouAwake = pkgs.callPackage ./keeping-you-awake.pkg.nix { };
      };
    };
}
