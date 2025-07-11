#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl gh
# shellcheck shell=bash

script="$0"
basename="$(dirname $script)"

function get_sha256() {
  curl -Ls $1 | sha256sum | cut -f 1 -d ' '
}

function generate_json() {
  githubData=$(gh api -H "Accept: application/vnd.github+json" /repos/rxhanson/Rectangle/releases/latest |
    jq '{version: .tag_name | sub("^v(?<v>.*)$"; .v)} * (.assets[]| select(.name|test("\\.dmg$")) | { id: .id, name: .name, url: .browser_download_url })')
  sha=$(get_sha256 $(jq --jsonargs -r '.url' <<<"$githubData"))

  jq -s add <<<"$githubData {\"sha256\": \"$sha\" }"
}

echo "Updating Rectangle"

json=$(generate_json)

echo "$json" | jq . >$basename/sources.json
