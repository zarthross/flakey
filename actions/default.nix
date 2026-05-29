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

  # Commit and force-push to branch (first job - creates branch)
  commitAndForcePush =
    { message, branch }:
    {
      uses = "EndBug/add-and-commit@v9";
      "with" = {
        default_author = "github_actions";
        message = message;
        add = "packages/**/default.nix";
        new_branch = branch;
        push = "origin ${branch} --force --set-upstream";
      };
    };

  # Commit and push to existing branch (subsequent jobs)
  commitAndPush =
    { message, branch }:
    {
      uses = "EndBug/add-and-commit@v9";
      "with" = {
        default_author = "github_actions";
        message = message;
        add = "packages/**/default.nix";
        new_branch = branch;
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
        jobs = {
          # Update packages on x86_64-linux
          update-x86_64-linux = {
            runs-on = "ubuntu-latest";
            steps = [
              checkout
              installNixAction
              runUpdateScript
              (commitAndForcePush {
                message = "Update packages for x86_64-linux";
                branch = "bot/update-packages";
              })
            ];
          };

          # Update packages on aarch64-darwin
          update-aarch64-darwin = {
            needs = [ "update-x86_64-linux" ];
            runs-on = "macos-14";
            steps = [
              (checkoutBranch "bot/update-packages")
              installNixAction
              runUpdateScript
              (commitAndPush {
                message = "Update packages for aarch64-darwin";
                branch = "bot/update-packages";
              })
            ];
          };

          # Merge to main (disabled for testing)
          merge-to-main = {
            "if" = "false"; # Disabled for testing
            needs = [ "update-aarch64-darwin" ];
            runs-on = "ubuntu-latest";
            steps = [
              checkout
              installNixAction
              runFlakeCheck
              {
                name = "Squash merge and push to main";
                run = ''
                  git config user.name "github-actions[bot]"
                  git config user.email "github-actions[bot]@users.noreply.github.com"
                  git fetch origin bot/update-packages
                  git merge --squash origin/bot/update-packages
                  if git diff --cached --quiet; then
                    echo "No changes to merge"
                  else
                    git commit -m "Update package versions"
                    git push origin main
                  fi
                  git push origin --delete bot/update-packages || true
                '';
              }
            ];
          };
        };
      };
    };
  };
}
