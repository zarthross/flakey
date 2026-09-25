{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];

  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    {
      config,
      self',
      pkgs,
      ...
    }:
    {
      devshells.default = {
        packages = [
          pkgs.jq
          pkgs.curl
          pkgs.gh
          pkgs.yq
        ];
        commands = [
          { package = pkgs.deadnix; }
          { package = config.treefmt.build.wrapper; }
          { package = config.pre-commit.settings.package; }
          {
            package = self'.packages.render-workflows;
            help = "Generates .github/workflow files for CI";
          }
          {
            name = "write-flake";
            help = "Regenerate flake.nix from modules/**/flake-file.inputs declarations";
            command = "exec nix run .#write-flake -- \"$@\"";
          }
          {
            name = "generate";
            help = "Regenerate flake.nix and .github/workflow files";
            command = "nix run .#write-flake && exec nix run .#render-workflows";
          }
        ];
        devshell.startup.pre-commit.text = config.pre-commit.installationScript;
      };
    };
}
