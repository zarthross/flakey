#!/usr/bin/env bash
# Mounted into Renovate's container via renovatebot/github-action's
# docker-cmd-file (see modules/repository/ci.nix's renovate job), replacing
# the default entrypoint. Runs as root (docker-user: root) so it can adjust
# PATH before dropping to the unprivileged "ubuntu" user Renovate normally
# runs as.
#
# The GitHub Actions runner's real /nix (store + running nix daemon, set up
# by installNixAction earlier in the same job) is bind-mounted into this
# container (see docker-volumes). We route postUpgradeTasks' nix invocations
# through that daemon instead of containerbase's installTools.nix, which
# installs a nix that can't substitute from any binary cache and builds the
# entire dependency closure from source on every run.
# https://github.com/containerbase/base/issues/7339
set -euo pipefail

NIX_BIN_DIR="/nix/var/nix/profiles/default/bin"

# `runuser` does not reliably preserve the caller's environment across
# versions/distros, so pass PATH and NIX_REMOTE through explicitly rather
# than relying on inheritance.
exec runuser -u ubuntu -- env "PATH=${NIX_BIN_DIR}:${PATH}" NIX_REMOTE=daemon renovate "$@"
