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
            name = "update-sources";
            help = "Update all package sources.json files (fetch, hash, write)";
            command = "exec \"$PRJ_ROOT/modules/repository/ci/run-update-all-sources.sh\" \"$@\"";
          }
        ];
        devshell.startup.pre-commit.text = config.pre-commit.installationScript;
      };
    };
}
