{ inputs, ... }:
let
  # Single source of truth for pinned GitHub Action versions/SHAs.
  # Kept as data (not Nix) so Renovate's JSONata custom manager can update it
  # directly. See .github/renovate.jsonc for the manager config that keeps
  # this file up to date.
  pinnedActions = builtins.fromJSON (builtins.readFile ./ci/pinned-actions.json);
  # Renders "owner/repo@<sha>" pinned to the commit SHA recorded in
  # pinned-actions.json. The human-readable version (e.g. "v4") lives only in
  # pinned-actions.json, not here.
  actionUses = name: "${name}@${pinnedActions.${name}.sha}";

  # Reusable action components
  checkout = {
    uses = actionUses "actions/checkout";
  };

  installNixAction = {
    uses = actionUses "cachix/install-nix-action";
    "with" = {
      nix_path = "nixpkgs=channel:nixos-unstable";
    };
  };

  runUpdateScript = {
    name = "Run update script";
    env.GH_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
    run = ''
      chmod +x ./modules/repository/ci/run-update-all-sources.sh
      ./modules/repository/ci/run-update-all-sources.sh
    '';
  };

  commitChanges = {
    uses = actionUses "EndBug/add-and-commit";
    "with" = {
      default_author = "github_actions";
      message = "Update package versions";
      add = "modules/**/sources.json";
    };
  };

  runFlakeCheck = {
    name = "Run nix flake check";
    run = "nix flake check";
  };

  runRenovate = {
    name = "Self-hosted Renovate";
    uses = actionUses "renovatebot/github-action";
    env = {
      LOG_LEVEL = "debug"; # TEMP: debugging "Repository has changed" abort
      # postUpgradeTasks run inside this container. Store operations
      # (build/substitute) go through the bind-mounted host nix daemon set
      # up by installNixAction above, so no store credentials need to be
      # injected here. Flake-input fetching (e.g. resolving flake.lock)
      # happens client-side though, so GITHUB_TOKEN is still passed
      # through, via RENOVATE_CUSTOM_ENV_VARIABLES (the only
      # env-injection mechanism that reaches postUpgradeTasks child
      # processes) routed through RENOVATE_SECRETS + {{ secrets.X }}
      # templating (rather than placing the raw value directly in
      # customEnvVariables) so it's redacted in logs.
      # https://docs.renovatebot.com/self-hosted-configuration/#customenvvariables
      RENOVATE_SECRETS = builtins.toJSON {
        GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
      };
      RENOVATE_CUSTOM_ENV_VARIABLES = builtins.toJSON {
        GITHUB_TOKEN = "{{ secrets.GITHUB_TOKEN }}";
      };
    };
    "with" = {
      configurationFile = ".github/renovate-global-config.json";
      token = "\${{ secrets.RENOVATE_TOKEN }}";
      # Pinned to an explicit patch version rather than left on the action's
      # default floating "44" major-version tag: a floating tag can start
      # resolving to a same-day, still-cooking Renovate image at any moment
      # with no warning, unlike every other action pin in this file which
      # goes through pinned-actions.json's SHA pinning. Kept up to date via
      # the customManager in .github/renovate.jsonc (guarded by the repo's
      # minimumReleaseAge cooldown, same as everything else).
      renovate-version = "44.68.3";
      # Bind-mounts the runner host's real nix (store + running daemon, set
      # up by installNixAction above) into Renovate's container, so
      # postUpgradeTasks' nix invocations substitute from cache.nixos.org
      # instead of building the whole dependency closure from source
      # (containerbase/base#7339). Must re-include the action's own default
      # (/tmp:/tmp) since providing this input overrides it rather than
      # adding to it.
      docker-volumes = "/tmp:/tmp ; /nix:/nix";
      # Runs as root long enough to fix up PATH/NIX_REMOTE for the
      # bind-mounted daemon, then drops to the unprivileged user Renovate
      # normally runs as.
      docker-cmd-file = "modules/repository/ci/renovate-docker-cmd.sh";
      docker-user = "root";
    };
  };
in
{
  imports = [ inputs.actions-nix.flakeModules.default ];

  flake-file.inputs.actions-nix = {
    url = "github:nialov/actions.nix";
    inputs.flake-parts.follows = "flake-parts";
    inputs.nixpkgs.follows = "nixpkgs";
    inputs.git-hooks.follows = "git-hooks-nix";
  };

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

      # Self-hosted Renovate - daily flake.lock (and, later, other
      # customManagers-driven) dependency update PRs. Auth via a
      # fine-grained PAT (secrets.RENOVATE_TOKEN), not a GitHub App -
      # this is a single personal repo, an App is unneeded overhead here.
      ".github/workflows/renovate.yaml" = {
        name = "renovate";
        on = {
          workflow_dispatch = { };
          schedule = [
            {
              # runs daily before 6am UTC, matching renovate.jsonc's
              # "before 6am" schedule window
              cron = "0 5 * * *";
            }
          ];
        };
        concurrency = {
          group = "renovate";
          cancel-in-progress = true;
        };
        jobs.renovate = {
          runs-on = "ubuntu-latest";
          steps = [
            checkout
            # Sets up a real, substitution-capable nix (daemon + populated
            # store) on the runner host, so Renovate's postUpgradeTasks can
            # use it via a bind mount instead of containerbase's
            # installTools.nix, which can't substitute from any binary
            # cache (see renovate-docker-cmd.sh and containerbase/base#7339).
            installNixAction
            runRenovate
          ];
        };
      };
    };
  };
}
