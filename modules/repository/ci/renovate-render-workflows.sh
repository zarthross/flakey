#!/usr/bin/env bash
# Invoked by Renovate's postUpgradeTasks (see .github/renovate.jsonc) after it
# updates modules/repository/ci/pinned-actions.json, so the Nix-rendered
# .github/workflows/*.yaml stay in sync with the new pinned SHAs in the same
# commit. Runs inside Renovate's own ephemeral container (see
# .github/renovate-global-config.json's allowedCommands + installTools.nix in
# the packageRules entry that references this script).
set -euo pipefail

nix \
  --extra-experimental-features 'nix-command flakes' \
  --accept-flake-config \
  --quiet --quiet \
  run .#render-workflows
