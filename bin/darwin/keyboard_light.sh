#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "keyboard_light: This script supports macOS only." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
readonly OBJC_SOURCE="${SCRIPT_DIR}/keyboard_light.m"
readonly HELPER_BINARY="${HOME}/.local/bin/keyboard_light"

# shellcheck disable=SC2034  # Used by `lib/light_common.sh`.
{
  readonly LIGHT_NAME="keyboard_light"
  readonly BRIGHTNESS_CACHE_FILE="${HOME}/.cache/keyboard-light-brightness"
  readonly OFF_THRESHOLD="0.01"
  readonly DEFAULT_BRIGHTNESS="0.25"
  readonly DEFAULT_COMMAND="toggle"
}

# clang + Foundation works; this machine's Swift toolchain cannot import Foundation.
compile_if_stale() {
  if [[ -x "${HELPER_BINARY}" && ! "${OBJC_SOURCE}" -nt "${HELPER_BINARY}" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "${HELPER_BINARY}")"
  clang -fobjc-arc -O2 -framework Foundation -o "${HELPER_BINARY}" "${OBJC_SOURCE}"
}

# Print the current keyboard backlight brightness.
# Outputs:
#   brightness (0.0000-1.0000) to STDOUT
get_brightness() {
  "${HELPER_BINARY}" get
}

# Set the keyboard backlight brightness, without validation or caching.
# Arguments:
#   ${1}: brightness (0.0-1.0)
apply_brightness() {
  "${HELPER_BINARY}" set "${1}"
}

# shellcheck source=/dev/null  # Lib sits next to the script.
source "${SCRIPT_DIR}/lib/light_common.sh"
compile_if_stale
main "$@"
