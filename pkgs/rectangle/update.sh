#!/usr/bin/env nix-shell
#!nix-shell -i bash -p jq curl
# shellcheck shell=bash

function get_version() {
    gh release list  -R rxhanson/Rectangle --exclude-drafts | grep Latest | cut  -f 3
}


function get_sha256() {
    curl -Ls $1 | sha256sum  | cut -f 1 -d ' '
}

function generate_json() {
    githubData=$(gh api -H "Accept: application/vnd.github+json" /repos/rxhanson/Rectangle/releases/latest | jq '{version: .tag_name} * (.assets[]| select(.name|test("\\.dmg$")) | { id: .id, name: .name, url: .browser_download_url })')
    sha=$(get_sha256 $(jq --jsonargs -r '.url' <<< "$githubData"))

    jq -s add <<< "$githubData {\"sha256\": \"$sha\" }"
}

json=$(generate_json)

echo "$json" | jq . > sources.json
