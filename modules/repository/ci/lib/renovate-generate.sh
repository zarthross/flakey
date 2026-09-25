#!/usr/bin/env bash
# Invoked by Renovate's postUpgradeTasks (see .github/renovate.jsonc) inside
# its own container. This container has the GitHub Actions runner's real nix
# daemon and store bind-mounted in (see modules/repository/ci/ci.nix's
# renovate job and renovate-docker-cmd.sh), so build/substitute operations go
# through that already-configured daemon - no store credentials need to be
# injected here at all (flakey only pulls from the public cache.nixos.org).
#
# NIX_CONFIG (access-tokens for client-side flake-input fetching, plus
# experimental-features) is set globally for all postUpgradeTasks via
# RENOVATE_CUSTOM_ENV_VARIABLES - see modules/repository/ci/ci.nix.
set -euo pipefail

nix \
  --accept-flake-config \
  --quiet --quiet \
  develop -c generate
