{ ... }:
let
  # Reusable action components
  checkout = {
    uses = "actions/checkout@v4";
  };

  # Checkout specific branch
  checkoutBranch = branch: {
    uses = "actions/checkout@v4";
    "with" = {
      ref = branch;
      fetch-depth = 0;
    };
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
      add = "packages/**/sources.json";
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
      # CI workflow - runs on all PRs
      ".github/workflows/ci.yaml" = {
        name = "CI";
        on = {
          pull_request = { };
          workflow_dispatch = { };
        };
        concurrency = {
          group = "\${{ github.workflow }}-\${{ github.ref }}";
          cancel-in-progress = true;
        };
        jobs.check = {
          runs-on = "\${{ matrix.os }}";
          strategy = {
            matrix = {
              os = [
                "macos-latest"
                "ubuntu-latest"
              ];
            };
          };
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
        concurrency = {
          group = "update-sources";
          cancel-in-progress = true;
        };
        jobs.update-sources = {
          runs-on = "ubuntu-latest";
          steps = [
            checkout
            installNixAction
            runUpdateScript
            runFlakeCheck
            commitChanges
          ];
        };
      };
    };
  };
}
