#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update jq
# shellcheck shell=bash

echo "Starting package updates"

# Auto-detect all packages from the flake across all systems
# Get unique package names from all systems
packages=$(nix flake show --json 2>/dev/null | jq -r '
  .packages 
  | to_entries[] 
  | .value 
  | keys[] 
' | sort -u)

if [[ -z "$packages" ]]; then
  echo "Error: Could not detect packages from flake"
  exit 1
fi

# Update each package using their passthru.updateScript
for pkg in $packages; do
  echo "Updating $pkg..."
  nix-update --flake --use-update-script "$pkg" || echo "Warning: Failed to update $pkg"
done

echo "Update complete"
