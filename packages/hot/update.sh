#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../../ci/lib/github-release-update.sh"

echo "Updating Hot"

update_github_release macmade Hot 'Hot(.app)?\.zip$' |
  jq . >"$(dirname "$0")/sources.json"

echo "✓ Updated"
