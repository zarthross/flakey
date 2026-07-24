{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  flake-file.inputs.treefmt-nix = {
    url = "github:numtide/treefmt-nix";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem = {
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
  };
}
