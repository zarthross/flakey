#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../../ci/lib/github-release-update.sh"

echo "Updating OmniWM"

update_github_release BarutSRB OmniWM '^OmniWM-v.+\.zip$' |
  jq . >"$(dirname "$0")/sources.json"

echo "✓ Updated"
