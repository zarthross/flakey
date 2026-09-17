#!/usr/bin/env bash
# Run via `nix develop -c ./update-hash.sh` (devshell provides jq/curl/gh).
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../repository/ci/lib/github-release-update.sh"
update_single_asset_hash "$(dirname "$0")/sources.json"
