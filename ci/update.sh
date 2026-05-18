#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update jq
# shellcheck shell=bash

set -euo pipefail

echo "Starting package updates"

# Auto-detect all packages from the flake across all systems
# Get unique package names from all systems
packages=$(nix flake show --json 2>/dev/null | jq -r '
  .packages 
  | to_entries[] 
  | .value 
  | keys[] 
' | sort -u)

if [[ -z $packages ]]; then
  echo "Error: Could not detect packages from flake"
  exit 1
fi

# Track failures
failed_packages=()

# Update each package using their passthru.updateScript
for pkg in $packages; do
  echo "Updating $pkg..."
  if ! nix-update --flake --use-update-script "$pkg"; then
    echo "Warning: Failed to update $pkg"
    failed_packages+=("$pkg")
  fi
done

echo "Update complete"

# Report failures with GitHub Actions annotations if in CI
if [[ ${#failed_packages[@]} -gt 0 ]]; then
  echo ""
  if [[ -n ${GITHUB_ACTIONS:-} ]]; then
    # GitHub Actions annotation format for better visibility
    echo "::error title=Package Update Failures::Failed to update ${#failed_packages[@]} package(s): ${failed_packages[*]}"
    echo ""
    echo "::group::Failed Packages"
    for pkg in "${failed_packages[@]}"; do
      echo "::error file=packages/$pkg/default.nix::Failed to update package: $pkg"
    done
    echo "::endgroup::"
  else
    # Standard output for local runs
    echo "Failed to update ${#failed_packages[@]} package(s):"
    printf '  - %s\n' "${failed_packages[@]}"
  fi
  exit 1
fi
