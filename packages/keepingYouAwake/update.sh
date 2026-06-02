#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

script="$0"
basename="$(dirname $script)"

function get_sha256() {
  curl -Ls $1 | sha256sum | cut -f 1 -d ' '
}

function generate_json() {
  githubData=$(gh api -H "Accept: application/vnd.github+json" /repos/newmarcel/KeepingYouAwake/releases/latest | jq '{version: .tag_name} * (.assets[]| select(.name|test("^KeepingYouAwake-.+zip$")) | { id: .id, name: .name, url: .browser_download_url })')
  sha=$(get_sha256 $(jq --jsonargs -r '.url' <<<"$githubData"))

  jq -s add <<<"$githubData {\"sha256\": \"$sha\" }"
}

echo "Updating KeepingYouAwake"

json=$(generate_json)

echo "$json" | jq . >$basename/sources.json
