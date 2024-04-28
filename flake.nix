{
  description =
    "A collection of stuff I wanted, and figured I'd share as a bunch of flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    let
      # TODO: Clean this up... maybe us flake-parts instead?
      bySystemDarwin = (flake-utils.lib.eachSystem [
        flake-utils.lib.system.x86_64-darwin
        flake-utils.lib.system.aarch64-darwin
      ] (system:
        let pkgs = import nixpkgs { inherit system; };
        in { packages = import ./pkgs-darwin { inherit inputs pkgs; }; }));
      bySystemLinux =
        (flake-utils.lib.eachSystem [ flake-utils.lib.system.x86_64-linux ]
          (system:
            let pkgs = import nixpkgs { inherit system; };
            in { packages = import ./pkgs-linux { inherit inputs pkgs; }; }));
      bySystem = {
        packages = {
          inherit (bySystemLinux.packages) "x86_64-linux";
          inherit (bySystemDarwin.packages) "aarch64-darwin";
          inherit (bySystemDarwin.packages) "x86_64-darwin";
        };
      };
    in bySystem // (rec {
      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./nixos-modules;
      homeModules = import ./home-manager-modules;
      homeManagerModules = homeModules; #Deprecated
      darwinModules = import ./darwin-modules;
    });
}
