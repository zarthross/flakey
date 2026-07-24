#!/usr/bin/env bash
# Reusable functions for updating packages from GitHub releases

# Usage: update_github_release OWNER REPO ASSET_PATTERN [VERSION_TRANSFORM]
# VERSION_TRANSFORM is a jq expression, default is just ".tag_name"
update_github_release() {
  local owner="$1"
  local repo="$2"
  local asset_pattern="$3"
  local version_transform="${4:-.tag_name}"

  local release
  release=$(gh api -H "Accept: application/vnd.github+json" "/repos/$owner/$repo/releases/latest")

  local data
  data=$(echo "$release" | jq --arg pattern "$asset_pattern" \
    "{version: ($version_transform)} * (.assets[] | select(.name | test(\$pattern)) | {id: .id, name: .name, url: .browser_download_url})")

  local url
  url=$(echo "$data" | jq -r '.url')

  local sha256
  sha256=$(curl -fsSL "$url" | sha256sum | awk '{print $1}')

  echo "$data" | jq --arg sha "$sha256" '. + {sha256: $sha}'
}

# Usage: update_github_release_filtered OWNER REPO ASSET_PATTERN TAG_FILTER [VERSION_TRANSFORM]
# TAG_FILTER is a jq select expression for filtering releases
update_github_release_filtered() {
  local owner="$1"
  local repo="$2"
  local asset_pattern="$3"
  local tag_filter="$4"
  local version_transform="${5:-.tag_name}"

  local releases
  releases=$(gh api -H "Accept: application/vnd.github+json" "/repos/$owner/$repo/releases")

  local release
  release=$(echo "$releases" | jq "map(select($tag_filter)) | .[0]")

  local data
  data=$(echo "$release" | jq --arg pattern "$asset_pattern" \
    "{version: ($version_transform)} * (.assets[] | select(.name | test(\$pattern)) | {id: .id, name: .name, url: .browser_download_url})")

  local url
  url=$(echo "$data" | jq -r '.url')

  local sha256
  sha256=$(curl -fsSL "$url" | sha256sum | awk '{print $1}')

  echo "$data" | jq --arg sha "$sha256" '. + {sha256: $sha}'
}
