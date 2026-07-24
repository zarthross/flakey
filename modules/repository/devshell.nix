{ inputs, ... }:
{
  imports = [ inputs.devshell.flakeModule ];

  flake-file.inputs.devshell = {
    url = "github:numtide/devshell";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { config, self', ... }:
    {
      devshells.default = {
        commands = [
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
        ];
        devshell.startup.pre-commit.text = config.pre-commit.installationScript;
      };
    };
}
