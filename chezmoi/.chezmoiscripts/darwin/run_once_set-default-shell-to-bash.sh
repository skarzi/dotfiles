#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

_SHELL_PATH="/opt/homebrew/bin/bash"

if ! grep -q "${_SHELL_PATH}" /etc/shells; then
  echo "${_SHELL_PATH}" | sudo tee -a /etc/shells
fi

chsh -s "${_SHELL_PATH}"
