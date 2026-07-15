{
  description = "A collection of stuff I wanted, and figured I'd share as a bunch of flakes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    nix-update.url = "github:Mic92/nix-update";
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    actions-nix = {
      url = "github:nialov/actions.nix";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.git-hooks.follows = "git-hooks-nix";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-parts,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = [
          ./packages
          inputs.devshell.flakeModule
          inputs.treefmt-nix.flakeModule
          inputs.git-hooks-nix.flakeModule
          inputs.actions-nix.flakeModules.default
          ./actions
        ];
        flake = {
          nixosModules = import ./nixos-modules;
          homeModules = import ./home-modules {
            inherit lib;
            localFlake = self;
          };
          homeManagerModules =
            builtins.trace "[1;31mwarning: homeManagerModules is Deprecated, please use homeModules.["
              (
                import ./home-modules {
                  inherit lib;
                  localFlake = self;
                }
              );
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
                { package = config.treefmt.build.wrapper; }
                { package = config.pre-commit.settings.package; }
                {
                  package = self'.packages.render-workflows;
                  help = "Generates .github/workflow files for CI";
                }
              ];
              devshell.startup.pre-commit.text = config.pre-commit.installationScript;
            };

            treefmt = {
              flakeCheck = true;
              projectRootFile = "flake.nix";
              programs.nixfmt.enable = true;
              programs.shfmt.enable = true;
              programs.taplo.enable = true;
              settings.global.excludes = [
                ".github/**"
                "README.md"
              ];
            };

            pre-commit = {
              check.enable = true;
              settings = {
                # Use prek (Rust) instead of pre-commit (Python)
                package = pkgs.prek;
                hooks = {
                  # Format code with treefmt
                  treefmt.enable = true;
                };
              };
            };
          };
      }
    );
}
