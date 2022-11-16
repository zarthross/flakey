#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gh yq jq curl nix
# shellcheck shell=bash

echo "Starting Update"

find ./pkgs -type f -name "update.sh" -exec {} \;
