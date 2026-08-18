{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
        bitwarden = pkgs.callPackage ./bitwarden.pkg.nix { };
      };
    };
}
