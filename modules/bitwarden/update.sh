#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq yq curl gh
# shellcheck shell=bash

set -euo pipefail

source "$(dirname "$0")/../repository/ci/lib/github-release-update.sh"

echo "Updating Bitwarden"

# Bitwarden is special: uses sha512 from a YAML file instead of downloading
get_sha512_from_yaml() {
  local yaml_url="$1"
  curl -fsSL "$yaml_url" | yq -r '.files | map(select(.url | test("\\.dmg$"))) | .[0].sha512'
}

releases=$(gh api -H 'Accept: application/vnd.github+json' /repos/bitwarden/clients/releases)

# Filter for desktop releases and get latest
data=$(echo "$releases" | jq '
  map(select(.tag_name | startswith("desktop-"))) 
  | max_by(.tag_name | split("-v") | .[1] | split(".") | map(tonumber)) 
  | {
      version: .tag_name | split("-v") | .[1],
      release_id: .id
    } 
    * (.assets | map(select(.name | test("\\.dmg$"))) | .[0] | {
        url: .browser_download_url, 
        asset_id: .id, 
        name: .name
      }) 
    * (.assets | map(select(.name | test("^latest-mac.yml$"))) | .[0] | {
        sha_url: .browser_download_url, 
        sha_asset_id: .id
      })
')

sha_url=$(echo "$data" | jq -r '.sha_url')
sha=$(get_sha512_from_yaml "$sha_url")

echo "$data" | jq --arg hash "sha512-$sha" '. + {hash: $hash} | del(.sha_url, .sha_asset_id)' \
  >"$(dirname "$0")/sources.json"

echo "✓ Updated"
