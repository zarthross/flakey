#!/usr/bin/env bash
# Reusable functions for refreshing a package's hash from a known release tag.
# Version discovery is Renovate's job now; these only fetch by exact tag.
#
# NIX_CONFIG's experimental-features is set globally for all postUpgradeTasks
# via RENOVATE_CUSTOM_ENV_VARIABLES - see modules/repository/ci/ci.nix. This
# is required for nested `nix` calls in this script (e.g. `nix hash convert`)
# since `nix develop`'s own --extra-experimental-features doesn't propagate
# to them, and they'd otherwise fail silently in Renovate's container and
# produce an empty hash.

# Usage: get_release_json OWNER REPO TAG
# Prints the raw release JSON, for scripts that need multiple assets from it
# (e.g. multi-platform packages).
get_release_json() {
  local owner="$1"
  local repo="$2"
  local tag="$3"

  gh api -H "Accept: application/vnd.github+json" "/repos/$owner/$repo/releases/tags/$tag"
}

# Usage: fetch_release_by_tag OWNER REPO TAG ASSET_PATTERN
# Prints {id, name, url, sha256} for the matching asset.
fetch_release_by_tag() {
  local owner="$1"
  local repo="$2"
  local tag="$3"
  local asset_pattern="$4"

  local release
  release=$(gh api -H "Accept: application/vnd.github+json" "/repos/$owner/$repo/releases/tags/$tag")

  local data
  data=$(echo "$release" | jq --arg pattern "$asset_pattern" \
    '.assets[] | select(.name | test($pattern)) | {id: .id, name: .name, url: .browser_download_url}')

  local url
  url=$(echo "$data" | jq -r '.url')

  local sha256
  sha256=$(curl -fsSL "$url" | sha256sum | awk '{print $1}')

  echo "$data" | jq --arg sha "$sha256" '. + {sha256: $sha}'
}

# Usage: _load_sources SOURCES_JSON_PATH
# Reads sources.json and sets the caller's sources/owner/repo/tag locals
# (bash dynamic scoping - caller must `local sources owner repo tag` first).
# Also prints the "Updating $repo hash" banner shared by both drivers below.
_load_sources() {
  local sources_path="$1"

  sources=$(cat "$sources_path")
  owner=$(echo "$sources" | jq -r '.owner')
  repo=$(echo "$sources" | jq -r '.repo')
  tag=$(echo "$sources" | jq -r '.tag')

  echo "Updating $repo hash"
}

# Usage: update_single_asset_hash SOURCES_JSON_PATH
# Full driver for single-asset packages (owner/repo/tag/asset_pattern at the
# top level of sources.json). An optional "version_transform" field (a
# raw-input jq filter, default ".") is applied to the tag to produce
# `version` - e.g. "sub(\"^v\"; \"\")" to strip a leading v.
update_single_asset_hash() {
  local sources_path="$1"

  local sources owner repo tag
  _load_sources "$sources_path"

  local asset_pattern version_transform version asset
  asset_pattern=$(echo "$sources" | jq -r '.asset_pattern')
  version_transform=$(echo "$sources" | jq -r '.version_transform // "."')
  version=$(echo -n "$tag" | jq -Rr "$version_transform")
  asset=$(fetch_release_by_tag "$owner" "$repo" "$tag" "$asset_pattern")

  if [[ -z "$(echo "$asset" | jq -r '.sha256')" ]]; then
    echo "error: empty sha256 for $repo@$tag" >&2
    exit 1
  fi

  echo "$sources" | jq --argjson asset "$asset" --arg version "$version" \
    '. + {version: $version} + $asset' >"$sources_path"

  echo "✓ Updated"
}

# Usage: update_multi_platform_hash SOURCES_JSON_PATH RESOLVER_FUNC
# Full driver for multi-platform packages (owner/repo/tag at the top level,
# per-platform sub-objects otherwise). RESOLVER_FUNC is called as
# `RESOLVER_FUNC RELEASE_JSON PLATFORM_JSON` for each platform key and must
# print {url, hash} for that platform.
update_multi_platform_hash() {
  local sources_path="$1"
  local resolver="$2"

  local sources owner repo tag
  _load_sources "$sources_path"

  local release
  release=$(get_release_json "$owner" "$repo" "$tag")

  local platform platform_json result
  for platform in $(echo "$sources" | jq -r 'keys[] | select(. as $k | ["owner","repo","tag","version"] | index($k) | not)'); do
    echo "  Processing $platform..."
    platform_json=$(echo "$sources" | jq -c --arg p "$platform" '.[$p]')
    result=$("$resolver" "$release" "$platform_json")

    if [[ -z "$(echo "$result" | jq -r '.hash')" ]]; then
      echo "error: empty hash for $repo@$tag ($platform)" >&2
      exit 1
    fi

    sources=$(echo "$sources" | jq --arg platform "$platform" --argjson result "$result" \
      '.[$platform] += $result')
  done

  echo "$sources" | jq --arg version "$tag" '. + {version: $version}' >"$sources_path"

  echo "✓ Updated"
}
