#!/usr/bin/env nix-shell
#!nix-shell -i bash -p nix-update jq
# shellcheck shell=bash

set -euo pipefail

echo "Starting package updates"

# Detect current system
current_system=$(nix eval --impure --raw --expr 'builtins.currentSystem')
echo "Current system: $current_system"

# Get packages available on current system only
packages=$(nix flake show --json 2>/dev/null | jq -r --arg system "$current_system" '
  .packages[$system] 
  | keys[] 
' | grep -v '^render-workflows$' | sort -u)

if [[ -z $packages ]]; then
  echo "No packages found for system $current_system"
  exit 0
fi

echo "Packages to update: $(echo "$packages" | wc -l)"

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
