{ ... }:
let
  # Reusable action components
  checkout = {
    uses = "actions/checkout@v4";
  };

  installNixAction = {
    uses = "cachix/install-nix-action@v30";
    "with" = {
      nix_path = "nixpkgs=channel:nixos-unstable";
    };
  };

  runUpdateScript = {
    name = "Run update script";
    env.GH_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
    run = ''
      chmod +x ./ci/update.sh
      ./ci/update.sh
    '';
  };

  commitChanges = {
    uses = "EndBug/add-and-commit@v9";
    "with" = {
      default_author = "github_actions";
      message = "Update package versions";
      add = "packages/**/default.nix";
    };
  };

  runFlakeCheck = {
    name = "Run nix flake check";
    run = "nix flake check";
  };
in
{
  flake.actions-nix = {
    # Enable pre-commit hook to auto-render workflows on commit
    pre-commit.enable = true;

    workflows = {
      # CI workflow - runs on all PRs and pushes
      ".github/workflows/ci.yaml" = {
        name = "CI";
        on = {
          pull_request = { };
          push.branches = [ "main" ];
        };
        jobs.check = {
          runs-on = "macos-latest";
          steps = [
            checkout
            installNixAction
            runFlakeCheck
          ];
        };
      };

      # Define the update-sources workflow
      ".github/workflows/update-sources.yaml" = {
        name = "update-sources";
        on = {
          workflow_dispatch = { };
          schedule = [
            {
              # runs every midnight
              cron = "0 0 * * *";
            }
          ];
          push.branches = [ "main" ];
        };
        jobs.update-sources = {
          runs-on = "macos-latest";
          steps = [
            checkout
            installNixAction
            runUpdateScript
            commitChanges
          ];
        };
      };
    };
  };
}
