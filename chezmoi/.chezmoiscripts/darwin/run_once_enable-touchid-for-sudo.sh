#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ ! -f "/etc/pam.d/sudo_local" ]]; then
  sudo cp /etc/pam.d/sudo_local.template /etc/pam.d/sudo_local
fi

sudo sed -i '' -e 's/^#[[:space:]]*auth/auth/' /etc/pam.d/sudo_local
