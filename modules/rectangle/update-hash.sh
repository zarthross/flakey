#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../repository/ci/lib/github-release-update.sh"
update_single_asset_hash "$(dirname "$0")/sources.json"
