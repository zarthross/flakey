{
  description =
    "A collection of stuff I wanted, and figured I'd share as a bunch of flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      bySystem = (flake-utils.lib.eachSystem [
        flake-utils.lib.system.x86_64-darwin
        flake-utils.lib.system.aarch64-darwin
      ] (system:
        let pkgs = import nixpkgs { inherit system; };
        in { packages = import ./pkgs { inherit inputs pkgs; }; }));
    in bySystem // {
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./nixos-modules;
      homeManagerModules = import ./home-manager-modules;
    };
}
