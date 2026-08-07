{ ... }:
{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages = lib.optionalAttrs pkgs.stdenv.isDarwin {
        bitwarden = pkgs.callPackage ./bitwarden.pkg.nix { };
      };
    };
}
