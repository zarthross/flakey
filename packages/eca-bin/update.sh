#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh nix
# shellcheck shell=bash

set -euo pipefail

script="$0"
basename="$(dirname "$script")"

# Platform to asset name mapping
declare -A PLATFORM_ASSETS=(
  ["x86_64-linux"]="eca-native-static-linux-amd64.zip"
  ["aarch64-linux"]="eca-native-linux-aarch64.zip"
  ["x86_64-darwin"]="eca-native-macos-amd64.zip"
  ["aarch64-darwin"]="eca-native-macos-aarch64.zip"
)

echo "Updating eca-bin"

# Get latest release
release=$(gh api -H "Accept: application/vnd.github+json" /repos/editor-code-assistant/eca/releases/latest)
version=$(echo "$release" | jq -r '.tag_name')

echo "Latest version: $version"

# Start building JSON with version
json="{\"version\": \"$version\"}"

# Process each platform
for platform in "${!PLATFORM_ASSETS[@]}"; do
  asset_name="${PLATFORM_ASSETS[$platform]}"
  sha_name="${asset_name}.sha256"

  echo "  Processing $platform..."

  # Get asset URL
  url=$(echo "$release" | jq -r --arg name "$asset_name" \
    '.assets[] | select(.name == $name) | .browser_download_url')

  # Get SHA256 file URL and fetch hash
  sha_url=$(echo "$release" | jq -r --arg name "$sha_name" \
    '.assets[] | select(.name == $name) | .browser_download_url')

  sha256=$(curl -fsSL "$sha_url" | awk '{print $1}')
  hash=$(nix hash convert --hash-algo sha256 "$sha256")

  # Add platform to JSON
  json=$(echo "$json" | jq --arg platform "$platform" \
    --arg url "$url" \
    --arg hash "$hash" \
    '. + {($platform): {url: $url, hash: $hash}}')
done

echo "$json" | jq . >"$basename/sources.json"

echo "✓ Updated sources.json"
