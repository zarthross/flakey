#!/usr/bin/env bash
# Invoked by Renovate's postUpgradeTasks (see .github/renovate.jsonc) inside
# its own container. This container has the GitHub Actions runner's real nix
# daemon and store bind-mounted in (see modules/repository/ci.nix's renovate
# job and renovate-docker-cmd.sh), so build/substitute operations go through
# that already-configured daemon - no store credentials need to be injected
# here at all (flakey only pulls from the public cache.nixos.org).
#
# Flake-input fetching (e.g. resolving flake.lock) happens client-side
# though, not through the daemon, so GITHUB_TOKEN is still needed here to
# avoid GitHub API rate limits. It's passed in via RENOVATE_CUSTOM_ENV_VARIABLES
# (see modules/repository/ci.nix), the only env-injection mechanism that
# reaches postUpgradeTasks child processes.
set -euo pipefail

export NIX_CONFIG="access-tokens = github.com=${GITHUB_TOKEN}"

nix \
  --extra-experimental-features 'nix-command flakes' \
  --accept-flake-config \
  --quiet --quiet \
  run .#render-workflows
