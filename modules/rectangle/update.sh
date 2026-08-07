#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../repository/ci/lib/github-release-update.sh"

echo "Updating Rectangle"

update_github_release rxhanson Rectangle '\.dmg$' '.tag_name | sub("^v"; "")' |
  jq . >"$(dirname "$0")/sources.json"

echo "✓ Updated"
