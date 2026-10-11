#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "display_light: This script supports macOS only." >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

# shellcheck disable=SC2034  # Used by `lib/light_common.sh`.
{
  readonly LIGHT_NAME="display_light"
  readonly BRIGHTNESS_CACHE_FILE="${HOME}/.cache/display-light-brightness"
  readonly OFF_THRESHOLD="0.01"
  readonly DEFAULT_BRIGHTNESS="0.6"
  # Required, so a bare call cannot black out the screen.
  readonly DEFAULT_COMMAND=""
}

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
  const level = parseFloat(argv[1]);
  const isLevel = /^(\d+|\d*\.\d+)$/.test(argv[1] || '') && level <= 1;
  if (argv[0] !== 'get' && !(argv[0] === 'set' && isLevel)) {
    fail('Expected "get" or "set" with a brightness from 0.0 to 1.0.');
  }
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
  if ($.DisplayServicesSetBrightness(display, level) !== 0) {
    fail('DisplayServices refused the brightness change.');
  }
  return undefined;
}
EOF
)"
readonly JXA

# Print the current built-in display brightness.
# Outputs:
#   brightness (0.0000-1.0000) to STDOUT
get_brightness() {
  osascript -l JavaScript -e "${JXA}" -- get
}

# Set the built-in display brightness, without validation or caching.
# Arguments:
#   ${1}: brightness (0.0-1.0)
apply_brightness() {
  osascript -l JavaScript -e "${JXA}" -- set "${1}"
}

# shellcheck source=/dev/null  # Lib sits next to the script.
source "${SCRIPT_DIR}/lib/light_common.sh"
main "$@"
