# shellcheck shell=bash

# Shared brightness logic of `display_light.sh` and `keyboard_light.sh`.
# Source it, then end the script with `main "$@"`. The sourcing script must
# define, before `main` runs:
#   LIGHT_NAME: script name without `.sh`, used in messages (`display_light`).
#   BRIGHTNESS_CACHE_FILE: file remembering the level to restore.
#   OFF_THRESHOLD: levels at or below it count as "off".
#   DEFAULT_BRIGHTNESS: restore level when the cache is unusable.
#   DEFAULT_COMMAND: command for a bare call; empty requires a command.
#   get_brightness: prints the current level (0.0-1.0).
#   apply_brightness: sets the level `${1}` (no validation, no caching).

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

# Set the brightness. Caches the current level first when this call goes to
# "off" from "on", so `toggle` can restore it. An "off" level never overwrites
# the cache, and an unreadable current level is skipped.
# Globals:
#   BRIGHTNESS_CACHE_FILE (written), OFF_THRESHOLD, LIGHT_NAME (read)
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
    echo "${LIGHT_NAME}: Brightness must be a number from 0.0 to 1.0." >&2
    echo "Usage: ${LIGHT_NAME}.sh set <0.0-1.0>" >&2
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
  apply_brightness "${brightness}"
}

# Toggle off, restoring the last non-zero level on the next toggle.
# Globals:
#   BRIGHTNESS_CACHE_FILE (written), OFF_THRESHOLD, DEFAULT_BRIGHTNESS (read)
toggle() {
  local current_brightness
  current_brightness="$(get_brightness)"
  if awk -v current_brightness="${current_brightness}" \
    -v off_threshold="${OFF_THRESHOLD}" \
    'BEGIN { exit !(current_brightness > off_threshold) }'; then
    if is_valid_brightness "${current_brightness}"; then
      cache_brightness "${current_brightness}"
    fi
    apply_brightness "0"
  else
    local restore_brightness="${DEFAULT_BRIGHTNESS}"
    local cached_brightness
    if [[ -s "${BRIGHTNESS_CACHE_FILE}" ]]; then
      cached_brightness="$(cat "${BRIGHTNESS_CACHE_FILE}")"
      # Restore only a full-string number in (OFF_THRESHOLD, 1].
      # 0 would keep the light off; 1.5 would fail in `set`.
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
# Globals:
#   DEFAULT_COMMAND, LIGHT_NAME (read)
# Arguments:
#   ${1}: command: `toggle`, `get`, or `set` (`${DEFAULT_COMMAND}` if omitted)
#   ${2}: brightness for `set` (0.0-1.0)
# Outputs:
#   error and usage to STDERR on an unknown command
# Returns:
#   1 on unknown command (or missing command when no default exists)
main() {
  local subcommand="${1:-${DEFAULT_COMMAND}}"
  local requested_brightness="${2:-}"
  local problem="Unknown command."
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
      if [[ -z "${DEFAULT_COMMAND}" ]]; then
        problem="Unknown or missing command."
      fi
      echo "${LIGHT_NAME}: ${problem}" >&2
      echo "Usage: ${LIGHT_NAME}.sh [toggle|get|set <0.0-1.0>]" >&2
      return 1
      ;;
  esac
}
