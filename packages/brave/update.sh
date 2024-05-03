#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh xxd coreutils
# shellcheck shell=bash

script="$0"
basename="$(dirname $script)"

function get_sha256() {
	curl -Ls "$1" | cut -f 1 -d ' ' | xxd -r -p | base64
}

function generate_json() {
	releases=$(gh api -H 'Accept: application/vnd.github+json' /repos/brave/brave-browser/releases\?per_page=100)

	release=$(jq 'map(select(.name | startswith("Release")) | select(.prerelease == false))  | max_by(.tag_name)' <<<$releases)

	version=$(jq '{ version: .tag_name[1:], release_id: .id }' <<<$release)

	x64DMG=$(jq '.assets | map(select(.name | test("^Brave-Browser-x64\\.dmg$"))) | .[0] | {x64: {url: .browser_download_url, asset_id: .id, name: .name}}' <<<$release)
	x64SHAJS=$(jq '.assets | map(select(.name | test("^Brave-Browser-x64\\.dmg.sha256$"))) | .[0] | {"x64-sha": {url: .browser_download_url, asset_id: .id, name: .name}}' <<<$release)
	arm64DMG=$(jq '.assets | map(select(.name | test("^Brave-Browser-arm64\\.dmg$"))) | .[0] | {arm64: {url: .browser_download_url, asset_id: .id, name: .name}}' <<<$release)
	arm64SHAJS=$(jq '.assets | map(select(.name | test("^Brave-Browser-arm64\\.dmg.sha256$"))) | .[0] | {"arm64-sha": {url: .browser_download_url, asset_id: .id, name: .name}}' <<<$release)

	arm64SHAURL=$(jq -r '."arm64-sha".url' <<<$arm64SHAJS)
	x64SHAURL=$(jq -r '."x64-sha".url' <<<$x64SHAJS)

	arm64Sha=$(get_sha256 "$arm64SHAURL")
	x64Sha=$(get_sha256 "$x64SHAURL")

	jq -n 'reduce inputs as $i ({}; . * $i)' <<<"$version $x64DMG $arm64DMG $x64SHAJS $arm64SHAJS {\"arm64\": {\"sha\":\"sha256-$arm64Sha\"}} {\"x64\": {\"sha\":\"sha256-$x64Sha\"}}"
}

echo "Updating Brave"

json=$(generate_json)

echo "$json" | jq . >$basename/sources.json
