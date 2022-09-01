#!/usr/bin/env nix-shell
#!nix-shell -i bash --pure -p gh yq jq curl
# shellcheck shell=bash

find ./pkgs -type f -name "update.sh" -exec {} \;
