{ ... }:
{
  flake-file.inputs.nix-update.url = "github:Mic92/nix-update";

  perSystem =
    { inputs', ... }:
    {
      devshells.default.packages = [ inputs'.nix-update.packages.default ];
    };
}
