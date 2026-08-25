#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "keyboard_light: macOS only" >&2
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

# Print the current keyboard backlight brightness.
# Outputs: brightness (0.0000-1.0000) to STDOUT.
get_brightness() {
  "${HELPER_BINARY}" get
}

# Set the keyboard backlight brightness.
# Arguments:
#   ${1}: brightness (0.0-1.0)
set_brightness() {
  local brightness="${1}"
  "${HELPER_BINARY}" set "${brightness}"
}

# Toggle the backlight off, restoring the last non-zero level on next toggle.
# Globals:
#   BRIGHTNESS_CACHE_FILE, OFF_THRESHOLD, DEFAULT_BRIGHTNESS (read);
#   BRIGHTNESS_CACHE_FILE (written)
toggle() {
  local current_brightness
  current_brightness="$(get_brightness)"
  if awk -v current_brightness="${current_brightness}" \
    -v off_threshold="${OFF_THRESHOLD}" \
    'BEGIN { exit !(current_brightness > off_threshold) }'; then
    mkdir -p "$(dirname "${BRIGHTNESS_CACHE_FILE}")"
    echo "${current_brightness}" > "${BRIGHTNESS_CACHE_FILE}"
    set_brightness "0"
  else
    local restore_brightness="${DEFAULT_BRIGHTNESS}"
    local cached_brightness
    if [[ -s "${BRIGHTNESS_CACHE_FILE}" ]]; then
      cached_brightness="$(cat "${BRIGHTNESS_CACHE_FILE}")"
      # Restore only a full-string number in (OFF_THRESHOLD, 1].
      # 0 would keep the lights off; 1.5 would fail in `set`.
      if [[ "${cached_brightness}" =~ ^([0-9]+|[0-9]*\.[0-9]+)$ ]] \
        && awk -v cached_brightness="${cached_brightness}" \
          -v off_threshold="${OFF_THRESHOLD}" \
          'BEGIN { exit !(cached_brightness > off_threshold && cached_brightness <= 1) }'; then
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
#   1 on unknown command or missing `set` argument
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
      if [[ -z "${requested_brightness}" ]]; then
        echo "usage: keyboard_light.sh set <0.0-1.0>" >&2
        return 1
      fi
      set_brightness "${requested_brightness}"
      ;;
    *)
      echo "usage: keyboard_light.sh [toggle|get|set <0.0-1.0>]" >&2
      return 1
      ;;
  esac
}

compile_if_stale
main "$@"
