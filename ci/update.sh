#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update
# shellcheck shell=bash

echo "Starting package updates with nix-update"

# Find all package directories and update them
# Directory names match attribute names for consistency
for pkg_dir in ./packages/*/; do
  pkg=$(basename "$pkg_dir")
  if [[ -d "$pkg_dir" ]]; then
    echo "Updating $pkg..."
    nix-update --flake --use-update-script "$pkg" || echo "Warning: Failed to update $pkg"
  fi
done

echo "Update complete"
