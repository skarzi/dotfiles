#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ -x /nix/var/nix/profiles/default/bin/nix || -x "${HOME}/.nix-profile/bin/nix" ]]; then
  exit 0
fi

curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix \
  | sh -s -- install --no-confirm
