{ inputs, ... }:
let
  # Pinned GitHub Action versions/SHAs, kept as data so Renovate's JSONata
  # custom manager (.github/renovate.jsonc) can update it directly.
  pinnedActions = builtins.fromJSON (builtins.readFile ./pinned-actions.json);
  # "owner/repo@<sha>" pinned to pinned-actions.json's sha; the readable
  # version (e.g. "v4") lives only there.
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

  runFlakeCheck = {
    name = "Run nix flake check";
    run = "nix flake check";
  };

  runRenovate = {
    name = "Self-hosted Renovate";
    uses = actionUses "renovatebot/github-action";
    env = {
      LOG_LEVEL = "debug"; # TEMP: debugging "Repository has changed" abort
      # GITHUB_TOKEN reaches postUpgradeTasks child processes only via
      # RENOVATE_CUSTOM_ENV_VARIABLES, routed through RENOVATE_SECRETS +
      # {{ secrets.X }} templating so it's redacted in logs (not placed
      # directly in customEnvVariables).
      # https://docs.renovatebot.com/self-hosted-configuration/#customenvvariables
      RENOVATE_SECRETS = builtins.toJSON {
        GITHUB_TOKEN = "\${{ secrets.GITHUB_TOKEN }}";
      };
      RENOVATE_CUSTOM_ENV_VARIABLES = builtins.toJSON {
        GITHUB_TOKEN = "{{ secrets.GITHUB_TOKEN }}";
        # Set globally (rather than per-script) so every postUpgradeTask -
        # update-hash.sh (all packages) and renovate-generate.sh alike -
        # gets the same nix-command/flakes support and GitHub auth for
        # client-side flake-input fetching, with one source of truth.
        NIX_CONFIG = "access-tokens = github.com={{ secrets.GITHUB_TOKEN }}\nexperimental-features = nix-command flakes";
      };
      RENOVATE_REPOSITORIES = "\${{ github.repository }}";
      RENOVATE_GIT_AUTHOR = ''"zarthross (via renovate)" <1111592+zarthross@users.noreply.github.com>'';
      RENOVATE_ONBOARDING = false;
      RENOVATE_REQUIRE_CONFIG = "required";
      RENOVATE_ALLOWED_COMMANDS = ''
        [
          "^bash modules/repository/ci/lib/renovate-generate\\.sh$",
          "^nix develop \\.\\./\\.\\. -c \\./update-hash\\.sh$"
        ]
      '';
    };
    "with" = {
      token = "\${{ secrets.RENOVATE_TOKEN }}";
      # Pinned to an explicit patch version rather than left on the action's
      # default floating "44" major-version tag: a floating tag can start
      # resolving to a same-day, still-cooking Renovate image at any moment
      # with no warning, unlike every other action pin in this file which
      # goes through pinned-actions.json's SHA pinning. Kept up to date via
      # the customManager in .github/renovate.jsonc (guarded by the repo's
      # minimumReleaseAge cooldown, same as everything else).
      renovate-version = "44.115.4";
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
      docker-cmd-file = "modules/repository/ci/lib/renovate-docker-cmd.sh";
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

      # Self-hosted Renovate - daily flake.lock (and, later, other
      # customManagers-driven) dependency update PRs. Auth via a
      # fine-grained PAT (secrets.RENOVATE_TOKEN), not a GitHub App -
      # this is a single personal repo, an App is unneeded overhead here.
      ".github/workflows/renovate.yaml" = {
        name = "renovate";
        on = {
          workflow_dispatch = { };
          # picks up dashboard/PR checkbox clicks immediately
          issues.types = [ "edited" ];
          pull_request.types = [ "edited" ];
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
          # Queue, don't cancel: with issues/pull_request triggers now
          # firing mid-run, cancelling could abort a run mid-git-push and
          # leave a branch half-committed.
          cancel-in-progress = false;
        };
        jobs.renovate = {
          runs-on = "ubuntu-latest";
          # schedule/dispatch always run. issues/pull_request only run for a
          # human's edit to the Dependency Dashboard issue or a renovate/*
          # PR - Renovate's own rewrites (sender.type == Bot) are filtered
          # out, or every run would retrigger itself.
          "if" = ''
            github.event_name == 'schedule' || github.event_name == 'workflow_dispatch' ||
            (github.event_name == 'issues' && github.event.sender.type == 'User' && github.event.issue.title == 'Dependency Dashboard') ||
            (github.event_name == 'pull_request' && github.event.sender.type == 'User' && startsWith(github.event.pull_request.head.ref, 'renovate/'))
          '';
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
