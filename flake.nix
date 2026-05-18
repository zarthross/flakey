{
  description = "A collection of stuff I wanted, and figured I'd share as a bunch of flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-update.url = "github:Mic92/nix-update";
    actions-nix = {
      url = "github:nialov/actions.nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./packages
        inputs.devshell.flakeModule
        inputs.treefmt-nix.flakeModule
        inputs.actions-nix.flakeModules.default
        ./actions
      ];
      flake = rec {
        nixosModules = import ./nixos-modules;
        homeModules = import ./home-modules;
        homeManagerModules = builtins.trace "[1;31mwarning: homeManagerModules is Deprecated, please use homeModules.[" homeModules;
        darwinModules = import ./darwin-modules;
      };
      systems = [
        "x86_64-darwin"
        "aarch64-darwin"
        "x86_64-linux"
        "aarch64-linux"
      ];
      perSystem =
        {
          pkgs,
          inputs',
          config,
          self',
          ...
        }:
        {
          devshells.default = {
            packages = [ inputs'.nix-update.packages.default ];
            commands = [
              {
                package = self'.packages.render-workflows;
                help = "Generates .github/workflow files for CI";
              }
            ];
          };
          treefmt = {
            projectRootFile = "flake.nix";
            programs.nixfmt.enable = true;
            programs.shfmt.enable = true;
            programs.taplo.enable = true;
            settings.global.excludes = [
              ".github/**"
              "README.md"
            ];
          };
        };
    };
}
