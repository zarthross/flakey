#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh nix
# shellcheck shell=bash

set -euo pipefail

dir="$(dirname "$0")"
source "$dir/../repository/ci/lib/github-release-update.sh"

# Assets ship with a published .sha256 sidecar, matched by exact name.
resolve_platform() {
  local release="$1" platform_json="$2"
  local asset_name sha_name url sha_url sha256 hash
  asset_name=$(echo "$platform_json" | jq -r '.asset_name')
  sha_name="${asset_name}.sha256"

  url=$(echo "$release" | jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url')
  sha_url=$(echo "$release" | jq -r --arg name "$sha_name" \
    '.assets[] | select(.name == $name) | .browser_download_url')

  sha256=$(curl -fsSL "$sha_url" | awk '{print $1}')
  hash=$(nix hash convert --hash-algo sha256 "$sha256")

  jq -n --arg url "$url" --arg hash "$hash" '{url: $url, hash: $hash}'
}

update_multi_platform_hash "$dir/sources.json" resolve_platform
