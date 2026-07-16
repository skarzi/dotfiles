#!/usr/bin/env bash
# shellcheck shell=bash

set -eufo pipefail

pam_reattach_path="$(brew --prefix pam-reattach)/lib/pam/pam_reattach.so"
sudo_local_path="/etc/pam.d/sudo_local"

if [[ ! -r "${pam_reattach_path}" ]]; then
  echo "pam_reattach module not found: ${pam_reattach_path}" >&2
  exit 1
fi

if [[ ! -f "${sudo_local_path}" ]]; then
  sudo cp /etc/pam.d/sudo_local.template "${sudo_local_path}"
fi

sudo sed -i '' -E \
  -e 's/^#[[:space:]]*(auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so)$/\1/' \
  -e '/^[[:space:]]*auth[[:space:]]+[^[:space:]]+[[:space:]]+.*pam_reattach\.so([[:space:]]|$)/d' \
  -e "/pam_tid\.so/i\\
auth       optional       ${pam_reattach_path}
" \
  "${sudo_local_path}"

# Require exactly one pam_reattach entry before pam_tid.
if ! awk -v module="${pam_reattach_path}" '
  $1 == "auth" && $2 == "optional" && $3 == module { reattach_count++; reattach_line = NR }
  $1 == "auth" && $2 == "sufficient" && $3 == "pam_tid.so" { touch_id_line = NR }
  END { exit reattach_count != 1 || reattach_line >= touch_id_line }
' "${sudo_local_path}"; then
  echo "Invalid Touch ID PAM configuration in ${sudo_local_path}" >&2
  exit 1
fi
