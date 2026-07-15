#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh nix
# shellcheck shell=bash

set -euo pipefail

script="$0"
basename="$(dirname "$script")"

# Platform to asset name mapping
declare -A PLATFORM_ASSETS=(
  ["x86_64-linux"]="drift_detector_linux"
  ["aarch64-darwin"]="drift_detector_macos_arm64"
)

printf 'Updating drift-detector\n'

# Get latest release
release=$(gh api -H "Accept: application/vnd.github+json" /repos/yellowstonesoftware/drift-detector/releases/latest)
version=$(printf '%s' "$release" | jq -r '.tag_name')

printf 'Latest version: %s\n' "$version"

# Start building JSON with version
json="{\"version\": \"$version\"}"

# Process each platform (no published .sha256 sidecar files, so hash the asset directly)
for platform in "${!PLATFORM_ASSETS[@]}"; do
  asset_prefix="${PLATFORM_ASSETS[$platform]}"

  printf '  Processing %s...\n' "$platform"

  # Get asset URL
  url=$(printf '%s' "$release" | jq -r --arg prefix "$asset_prefix" \
    '.assets[] | select(.name | startswith($prefix)) | .browser_download_url')

  hash=$(nix store prefetch-file --json "$url" | jq -r '.hash')

  # Add platform to JSON
  json=$(printf '%s' "$json" | jq --arg platform "$platform" \
    --arg url "$url" \
    --arg hash "$hash" \
    '. + {($platform): {url: $url, hash: $hash}}')
done

printf '%s' "$json" | jq . >"$basename/sources.json"

printf '✓ Updated sources.json\n'
