#!/usr/bin/env bash
# Run via `nix develop -c ./update-hash.sh` (devshell provides jq/curl/gh/yq).
# shellcheck shell=bash

set -euo pipefail

dir="$(dirname "$0")"
source "$dir/../repository/ci/lib/github-release-update.sh"

sources=$(cat "$dir/sources.json")
owner=$(echo "$sources" | jq -r '.owner')
repo=$(echo "$sources" | jq -r '.repo')
tag=$(echo "$sources" | jq -r '.tag')
asset_pattern=$(echo "$sources" | jq -r '.asset_pattern')
hash_source_pattern=$(echo "$sources" | jq -r '.hash_source_pattern')
version_transform=$(echo "$sources" | jq -r '.version_transform')

echo "Updating $repo hash"

version=$(echo -n "$tag" | jq -Rr "$version_transform")
release=$(get_release_json "$owner" "$repo" "$tag")

asset=$(echo "$release" | jq --arg pattern "$asset_pattern" \
  '.assets[] | select(.name | test($pattern)) | {url: .browser_download_url, asset_id: .id, name: .name}')

sha_url=$(echo "$release" | jq -r --arg pattern "$hash_source_pattern" \
  '.assets[] | select(.name | test($pattern)) | .browser_download_url')

# Bitwarden's sha512 comes from a YAML sidecar file, not the .dmg itself
sha=$(curl -fsSL "$sha_url" | yq -r '.files | map(select(.url | test("\\.dmg$"))) | .[0].sha512')

echo "$sources" | jq --arg version "$version" --argjson release_id "$(echo "$release" | jq '.id')" \
  --argjson asset "$asset" --arg hash "sha512-$sha" \
  '. + {version: $version, release_id: $release_id} + $asset + {hash: $hash}' >"$dir/sources.json"

echo "✓ Updated"
