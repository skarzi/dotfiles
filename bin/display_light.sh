#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "display_light: This script supports macOS only." >&2
  exit 1
fi

readonly BRIGHTNESS_CACHE_FILE="${HOME}/.cache/display-light-brightness"
readonly OFF_THRESHOLD="0.01"
readonly DEFAULT_BRIGHTNESS="0.6"

# JXA bridge to the private `DisplayServices.framework`, run via `osascript`.
# Arguments (after `--`): `get` or `set <0.0-1.0>`.
# Never bind `AmbientLightCompensation` functions here: they take `(id, bool *)`
# and a wrong binding segfaults `osascript`.
JXA="$(
  cat << 'EOF'
ObjC.import('stdlib');
ObjC.import('AppKit');

function fail(message) {
  console.log('display_light: ' + message);
  $.exit(1);
}

function run(argv) {
  const bundle = $.NSBundle.bundleWithPath(
    '/System/Library/PrivateFrameworks/DisplayServices.framework');
  if (!bundle.load) {
    fail('Failed to load DisplayServices.framework.');
  }
  ObjC.bindFunction('DisplayServicesGetBrightness',
    ['int', ['unsigned int', 'float *']]);
  ObjC.bindFunction('DisplayServicesSetBrightness',
    ['int', ['unsigned int', 'float']]);
  ObjC.bindFunction('DisplayServicesCanChangeBrightness',
    ['bool', ['unsigned int']]);
  ObjC.bindFunction('CGDisplayIsBuiltin', ['bool', ['unsigned int']]);

  const display = ObjC.unwrap($.NSScreen.screens)
    .map((s) => ObjC.unwrap(s.deviceDescription.objectForKey('NSScreenNumber')))
    .find((id) => $.CGDisplayIsBuiltin(id));
  if (display === undefined || !$.DisplayServicesCanChangeBrightness(display)) {
    fail('No adjustable built-in display was found.');
  }

  if (argv[0] === 'get') {
    const ref = Ref();
    if ($.DisplayServicesGetBrightness(display, ref) !== 0) {
      fail('Failed to read the display brightness.');
    }
    return ref[0].toFixed(4);
  }
  if ($.DisplayServicesSetBrightness(display, parseFloat(argv[1])) !== 0) {
    fail('DisplayServices refused the brightness change.');
  }
  return undefined;
}
EOF
)"
readonly JXA

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

# Print the current built-in display brightness.
# Outputs:
#   brightness (0.0000-1.0000) to STDOUT
get_brightness() {
  osascript -l JavaScript -e "${JXA}" -- get
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

# Set the built-in display brightness.
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
    echo "display_light: Brightness must be a number from 0.0 to 1.0." >&2
    echo "Usage: display_light.sh set <0.0-1.0>" >&2
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
  osascript -l JavaScript -e "${JXA}" -- set "${brightness}"
}

# Toggle the display off, restoring the last non-zero level on next toggle.
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
      # 0 would keep the display off; 1.5 would fail in `set`.
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
#   ${1}: command: `toggle`, `get`, or `set` (required, so a bare call
#        cannot black out the screen)
#   ${2}: brightness for `set` (0.0-1.0)
# Returns:
#   1 on missing or unknown command, or missing `set` argument
main() {
  local subcommand="${1:-}"
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
      echo "display_light: Unknown or missing command." >&2
      echo "Usage: display_light.sh [toggle|get|set <0.0-1.0>]" >&2
      return 1
      ;;
  esac
}

main "$@"
