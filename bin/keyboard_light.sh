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
readonly BRIGHTNESS_CACHE_FILE="${HOME}/.cache/keyboard-light-brightness"
readonly OFF_THRESHOLD="0.01"
readonly DEFAULT_BRIGHTNESS="0.25"

# clang + Foundation works; this machine's Swift toolchain cannot import Foundation.
compile_if_stale() {
  if [[ -x "${HELPER_BINARY}" && ! "${OBJC_SOURCE}" -nt "${HELPER_BINARY}" ]]; then
    return 0
  fi
  mkdir -p "$(dirname "${HELPER_BINARY}")"
  clang -fobjc-arc -O2 -framework Foundation -o "${HELPER_BINARY}" "${OBJC_SOURCE}"
}

# Check that a string is a brightness in [0, 1].
# Accepts digits or digits with a decimal part (`0`, `1`, `.5`, `0.25`).
# Stricter than `strtof`: rejects `1e-1`, `+0.3`, `5.`, and negatives.
# Arguments:
#   ${1}: candidate brightness
# Returns:
#   `0` if valid, `1` otherwise
is_valid_brightness() {
  local brightness="${1}"
  [[ "${brightness}" =~ ^([0-9]+|[0-9]*\.[0-9]+)$ ]] \
    && awk -v brightness="${brightness}" \
      'BEGIN { exit !(brightness <= 1) }'
}

# Print the current keyboard backlight brightness.
# Outputs:
#   brightness (0.0000-1.0000) to STDOUT
get_brightness() {
  "${HELPER_BINARY}" get
}

# Remember a brightness level for the next `toggle` restore.
# Globals:
#   BRIGHTNESS_CACHE_FILE (written)
# Arguments:
#   ${1}: brightness (0.0-1.0)
cache_brightness() {
  local brightness="${1}"
  mkdir -p "$(dirname "${BRIGHTNESS_CACHE_FILE}")"
  echo "${brightness}" > "${BRIGHTNESS_CACHE_FILE}"
}

# Set the keyboard backlight brightness.
# Caches the current level first when this call dims to "off" from "on", so
# `toggle` can restore it. An "off" level never overwrites the cache, and an
# unreadable current level is skipped.
# Globals:
#   BRIGHTNESS_CACHE_FILE (written), OFF_THRESHOLD (read)
# Arguments:
#   ${1}: brightness (0.0-1.0)
# Outputs:
#   error and usage to STDERR on invalid brightness
# Returns:
#   `1` if brightness is not a number in [0, 1]
set_brightness() {
  local brightness="${1}"
  local current_brightness=""
  if ! is_valid_brightness "${brightness}"; then
    echo "keyboard_light: Brightness must be a number from 0.0 to 1.0." >&2
    echo "Usage: keyboard_light.sh set <0.0-1.0>" >&2
    return 1
  fi
  if awk -v brightness="${brightness}" -v off_threshold="${OFF_THRESHOLD}" \
    'BEGIN { exit !(brightness <= off_threshold) }'; then
    current_brightness="$(get_brightness)" || current_brightness=""
    if is_valid_brightness "${current_brightness}" \
      && awk -v current_brightness="${current_brightness}" \
        -v off_threshold="${OFF_THRESHOLD}" \
        'BEGIN { exit !(current_brightness > off_threshold) }'; then
      cache_brightness "${current_brightness}"
    fi
  fi
  "${HELPER_BINARY}" set "${brightness}"
}

# Toggle the backlight off, restoring the last non-zero level on next toggle.
# Globals:
#   BRIGHTNESS_CACHE_FILE, OFF_THRESHOLD, DEFAULT_BRIGHTNESS (read)
toggle() {
  local current_brightness
  current_brightness="$(get_brightness)"
  if awk -v current_brightness="${current_brightness}" \
    -v off_threshold="${OFF_THRESHOLD}" \
    'BEGIN { exit !(current_brightness > off_threshold) }'; then
    # `set_brightness` caches the current level before dimming.
    set_brightness "0"
  else
    local restore_brightness="${DEFAULT_BRIGHTNESS}"
    local cached_brightness
    if [[ -s "${BRIGHTNESS_CACHE_FILE}" ]]; then
      cached_brightness="$(cat "${BRIGHTNESS_CACHE_FILE}")"
      # Restore only a full-string number in (OFF_THRESHOLD, 1].
      # 0 would keep the lights off; 1.5 would fail in `set`.
      if is_valid_brightness "${cached_brightness}" \
        && awk -v cached_brightness="${cached_brightness}" \
          -v off_threshold="${OFF_THRESHOLD}" \
          'BEGIN { exit !(cached_brightness > off_threshold) }'; then
        restore_brightness="${cached_brightness}"
      fi
    fi
    set_brightness "${restore_brightness}"
  fi
}

# Dispatch the CLI.
# Arguments:
#   ${1}: command: `toggle` (default), `get`, or `set`
#   ${2}: brightness for `set` (0.0-1.0)
# Returns:
#   1 on unknown command
main() {
  local subcommand="${1:-toggle}"
  local requested_brightness="${2:-}"
  case "${subcommand}" in
    toggle)
      toggle
      ;;
    get)
      get_brightness
      ;;
    set)
      set_brightness "${requested_brightness}"
      ;;
    *)
      echo "keyboard_light: Unknown command." >&2
      echo "Usage: keyboard_light.sh [toggle|get|set <0.0-1.0>]" >&2
      return 1
      ;;
  esac
}

compile_if_stale
main "$@"
