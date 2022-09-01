#!/usr/bin/env nix-shell
#!nix-shell -i bash -p gh yq jq curl
# shellcheck shell=bash

find ./pkgs -type f -name "update.sh" -exec bash {} \;
