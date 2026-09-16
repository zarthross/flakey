#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh nix
# shellcheck shell=bash

set -euo pipefail

dir="$(dirname "$0")"
source "$dir/../repository/ci/lib/github-release-update.sh"

# No published sidecar hash, so hash the asset directly via the nix daemon.
resolve_platform() {
  local release="$1" platform_json="$2"
  local asset_pattern url hash
  asset_pattern=$(echo "$platform_json" | jq -r '.asset_pattern')

  url=$(echo "$release" | jq -r --arg pattern "$asset_pattern" \
    '.assets[] | select(.name | test($pattern)) | .browser_download_url')
  hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')

  jq -n --arg url "$url" --arg hash "$hash" '{url: $url, hash: $hash}'
}

update_multi_platform_hash "$dir/sources.json" resolve_platform
