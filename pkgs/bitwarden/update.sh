#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq yq curl gh
# shellcheck shell=bash

script="$0"
basename="$(dirname $script)"


function get_sha512() {    
    shaFile=$(curl -Ls $1)
    yq -r '.files | map(select(.url | test("\\.dmg$"))) | .[0].sha512' <<< "$shaFile"
}

function generate_json() {
    releases=$(gh api -H 'Accept: application/vnd.github+json' /repos/bitwarden/clients/releases)

    data=$(jq 'map(select(.tag_name | startswith("desktop-"))) | max_by(.tag_name) | { version: .tag_name | split("-v") | .[1], release_id: .id, } * (.assets | map(select(.name | test("\\.dmg$"))) | .[0] | {url: .browser_download_url, asset_id: .id, name: .name}) * (.assets | map(select(.name | test("^latest-mac.yml$"))) | .[0] | {sha_url: .browser_download_url, sha_asset_id: .id}) '\
      <<< "$releases")
    
    sha=$(get_sha512 $(jq --jsonargs -r '.sha_url' <<< "$data"))

    jq -s add <<< "$data {\"hash\": \"sha512-$sha\" }"
}

echo "Updating Bitwarden"

json=$(generate_json)

echo "$json" | jq . > $basename/sources.json
