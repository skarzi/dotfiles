#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "text_replacements: This script supports macOS only." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly OBJC_SOURCE="${SCRIPT_DIR}/text_replacements.m"
readonly HELPER_BINARY="${HOME}/.local/bin/text_replacements"

compile_if_stale() {
  if [[ -x "${HELPER_BINARY}" && ! "${OBJC_SOURCE}" -nt "${HELPER_BINARY}" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "${HELPER_BINARY}")"
  clang -fobjc-arc -O2 -framework Foundation -o "${HELPER_BINARY}" "${OBJC_SOURCE}"
}

compile_if_stale
exec "${HELPER_BINARY}" "$@"
