#!/usr/bin/env bash
# Invoked by Renovate's postUpgradeTasks (see .github/renovate.jsonc) after it
# updates modules/repository/ci/pinned-actions.json, so the Nix-rendered
# .github/workflows/*.yaml stay in sync with the new pinned SHAs in the same
# commit. Runs inside Renovate's own ephemeral container (see
# .github/renovate-global-config.json's allowedCommands + installTools.nix in
# the packageRules entry that references this script).
set -euo pipefail

# TODO(containerbase/base#7339): --store works around Containerbase forcing a
# non-default NIX_STORE_DIR (which breaks all binary cache substitution -
# every build falls through to building from source, including things like
# tinycc that fail outright in this sandboxed environment).
# https://github.com/containerbase/base/issues/7339
# root= relocates the physical files; store= is also required, since the
# wrapper's exported NIX_STORE_DIR would otherwise still win as the default
# for the logical store dir that cache substitution checks against.
NIX_STORE_ROOT="${CONTAINERBASE_CACHE_DIR:-$(mktemp -d)}/nix-store-root"

nix \
  --extra-experimental-features 'nix-command flakes' \
  --accept-flake-config \
  --quiet --quiet \
  --store "local?root=${NIX_STORE_ROOT}&store=/nix/store" \
  run .#render-workflows
